-- Ghost-text autocomplete backed by the Claude Code CLI (`claude -p`).
--
-- One persistent worker process (stream-json in/out, thinking disabled,
-- haiku at low effort) serves debounced completion requests while typing.
-- Suggestions stream in as dimmed virtual text at the cursor; any edit,
-- cursor move, or leaving insert mode dismisses them. Only the newest
-- request is honored ("gen" counter) and at most one is in flight; the
-- worker is recycled every max_turns completions so its conversation
-- history (and per-request input cost) stays bounded.

local M = {}

local ns = vim.api.nvim_create_namespace("claude_autocomplete")

local config = {
	enabled = true,
	debounce_ms = 400,
	accept_key = "<C-l>",
	toggle_key = "<leader>ta",
	model = "haiku",
	context_before = 60, -- lines of context above the cursor
	context_after = 20, -- lines of context below the cursor
	max_turns = 25, -- recycle the worker after this many completions
	max_output_tokens = 160, -- hard cap per suggestion (bounds latency too)
}

local system_prompt = table.concat({
	"You are an inline code completion engine.",
	"The user message is a code file split at the cursor: everything before",
	"and after <CURSOR> already exists in the buffer and will stay exactly as",
	"it is. Output ONLY the raw text to insert at <CURSOR> - the minimal",
	"insertion that connects the code before the cursor to the code after it.",
	"NEVER repeat, rewrite, or close code that already appears after <CURSOR>.",
	"Usually the right insertion is the rest of the current line, or a single",
	"line; produce several lines only when the surrounding code clearly calls",
	"for it (e.g. an empty function body). If the code is already complete and",
	"nothing needs inserting, output nothing at all.",
	"No explanation, no markdown fences, no commentary.",
	"Match the file's existing indentation style.",
	"Each request is independent; ignore previous requests.",
}, " ")

-- Worker state
local job = nil
local turns = 0
local stdout_tail = ""

-- Request state
local gen = 0 -- bumped on every new request and on invalidation
local in_flight = false
local pending = nil -- newest request queued while another is in flight
local current = nil -- request the worker is answering right now
local accumulated = ""
local timer = nil

local suggestion = nil -- { text, row, col, bufnr }

local function stop_timer()
	if timer then
		vim.fn.timer_stop(timer)
		timer = nil
	end
end

local function stop_worker()
	if job then
		vim.fn.jobstop(job)
		job = nil
	end
	turns = 0
	stdout_tail = ""
	in_flight = false
	pending = nil
end

local function clear_ghost()
	if suggestion and vim.api.nvim_buf_is_valid(suggestion.bufnr) then
		vim.api.nvim_buf_clear_namespace(suggestion.bufnr, ns, 0, -1)
	end
	suggestion = nil
end

-- Drop the ghost and mark any in-flight response as stale
local function invalidate()
	gen = gen + 1
	clear_ghost()
end

-- Cut a suggestion off at the point where it starts re-typing code that
-- already exists below the cursor (chat models love to rewrite the rest of
-- the block instead of inserting the one missing piece). Only lines with
-- some substance (> 3 chars trimmed) count as duplicates, so legitimate
-- short closers like "}", "end", or ");" are never trimmed away.
local function trim_overlap(req, text)
	local line = vim.api.nvim_buf_get_lines(req.bufnr, req.row, req.row + 1, false)[1] or ""
	local lines = vim.split(text, "\n", { plain = true })

	-- Same-line case: don't re-type what already follows the cursor
	local suffix = vim.trim(line:sub(req.col + 1))
	if #lines == 1 and #suffix > 3 then
		local first = lines[1]:gsub("%s+$", "")
		if vim.endswith(first, suffix) then
			lines[1] = first:sub(1, #first - #suffix):gsub("%s+$", "")
		end
	end

	-- Multi-line case: stop at the first line that duplicates the next
	-- existing non-blank line below the cursor
	local below = vim.api.nvim_buf_get_lines(req.bufnr, req.row + 1, req.row + 1 + config.context_after, false)
	local next_line
	for _, l in ipairs(below) do
		if vim.trim(l) ~= "" then
			next_line = vim.trim(l)
			break
		end
	end
	if next_line and #next_line > 3 then
		for i = 1, #lines do
			if vim.trim(lines[i]) == next_line then
				lines = vim.list_slice(lines, 1, i - 1)
				break
			end
		end
	end
	return table.concat(lines, "\n")
end

local function render(req, text)
	-- Only render while the cursor is still exactly where the request was made
	if not vim.api.nvim_buf_is_valid(req.bufnr) or vim.api.nvim_get_current_buf() ~= req.bufnr then
		return
	end
	local pos = vim.api.nvim_win_get_cursor(0)
	if pos[1] - 1 ~= req.row or pos[2] ~= req.col then
		return
	end

	text = trim_overlap(req, text):gsub("%s+$", "")
	if text == "" then
		-- Everything the model produced duplicates existing code: no ghost,
		-- and drop one shown earlier in this stream if it's now all-duplicate
		if suggestion and suggestion.bufnr == req.bufnr and suggestion.row == req.row and suggestion.col == req.col then
			clear_ghost()
		end
		return
	end

	local lines = vim.split(text, "\n", { plain = true })
	local virt_lines = {}
	for i = 2, #lines do
		virt_lines[#virt_lines + 1] = { { lines[i], "ClaudeGhostText" } }
	end
	vim.api.nvim_buf_clear_namespace(req.bufnr, ns, 0, -1)
	local ok = pcall(vim.api.nvim_buf_set_extmark, req.bufnr, ns, req.row, req.col, {
		virt_text = { { lines[1], "ClaudeGhostText" } },
		virt_text_pos = "inline",
		virt_lines = #virt_lines > 0 and virt_lines or nil,
	})
	if ok then
		suggestion = { text = text, row = req.row, col = req.col, bufnr = req.bufnr }
	end
end

local function handle_event(ev)
	if ev.type == "stream_event" and current then
		local e = ev.event or {}
		if e.type == "content_block_delta" and (e.delta or {}).type == "text_delta" then
			accumulated = accumulated .. e.delta.text
			if current.gen == gen then
				render(current, accumulated)
			end
		end
	elseif ev.type == "result" then
		in_flight = false
		turns = turns + 1
		local final = type(ev.result) == "string" and ev.result or accumulated
		if current and current.gen == gen and not ev.is_error then
			render(current, final)
		end
		current = nil
		if ev.is_error or turns >= config.max_turns then
			stop_worker() -- a fresh worker is spawned on the next request
		end
		if pending then
			local req = pending
			pending = nil
			M._send(req)
		end
	end
end

local function ensure_worker()
	if job then
		return true
	end
	-- luacheck: no max line length
	job = vim.fn.jobstart({
		"claude",
		"-p",
		"--model",
		config.model,
		"--effort",
		"low",
		"--system-prompt",
		system_prompt,
		"--tools",
		"",
		"--no-session-persistence",
		"--disable-slash-commands",
		"--setting-sources",
		"",
		"--input-format",
		"stream-json",
		"--output-format",
		"stream-json",
		"--include-partial-messages",
		"--verbose",
	}, {
		env = {
			MAX_THINKING_TOKENS = "0",
			CLAUDE_CODE_MAX_OUTPUT_TOKENS = tostring(config.max_output_tokens),
		},
		on_stdout = function(_, data)
			data[1] = stdout_tail .. data[1]
			stdout_tail = table.remove(data)
			for _, line in ipairs(data) do
				if line ~= "" then
					local ok, ev = pcall(vim.json.decode, line)
					if ok and type(ev) == "table" then
						handle_event(ev)
					end
				end
			end
		end,
		on_exit = function()
			job = nil
			in_flight = false
			current = nil
		end,
	})
	if job <= 0 then
		job = nil
		vim.notify("claude autocomplete: failed to start `claude` worker", vim.log.levels.WARN)
		return false
	end
	return true
end

function M._send(req)
	if not ensure_worker() then
		return
	end
	in_flight = true
	current = req
	accumulated = ""
	local msg = vim.json.encode({
		type = "user",
		message = { role = "user", content = { { type = "text", text = req.text } } },
	})
	vim.fn.chansend(job, msg .. "\n")
end

local function build_request()
	local bufnr = vim.api.nvim_get_current_buf()
	local pos = vim.api.nvim_win_get_cursor(0)
	local row, col = pos[1] - 1, pos[2]

	local start_row = math.max(0, row - config.context_before)
	local before = vim.api.nvim_buf_get_lines(bufnr, start_row, row, false)
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	local after = vim.api.nvim_buf_get_lines(bufnr, row + 1, row + 1 + config.context_after, false)

	local before_text = table.concat(before, "\n")
	if #before > 0 then
		before_text = before_text .. "\n"
	end
	local after_text = line:sub(col + 1)
	if #after > 0 then
		after_text = after_text .. "\n" .. table.concat(after, "\n")
	end

	local name = vim.fn.expand("%:t")
	local text = ("File: %s\nLanguage: %s\n\n%s%s<CURSOR>%s"):format(
		name ~= "" and name or "(unnamed)",
		vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or "unknown",
		before_text,
		line:sub(1, col),
		after_text
	)
	return { bufnr = bufnr, row = row, col = col, text = text }
end

-- Request a completion for the current cursor position immediately
-- (the autocmds normally call this via the debounce timer)
function M.trigger()
	if vim.bo.buftype ~= "" then
		return
	end
	local req = build_request()
	gen = gen + 1
	req.gen = gen
	if in_flight then
		pending = req
	else
		M._send(req)
	end
end

function M.accept()
	if not suggestion or not vim.api.nvim_buf_is_valid(suggestion.bufnr) then
		return
	end
	local s = suggestion
	clear_ghost()
	local lines = vim.split(s.text, "\n", { plain = true })
	vim.api.nvim_buf_set_text(s.bufnr, s.row, s.col, s.row, s.col, lines)
	local last_row = s.row + #lines - 1
	local last_col = #lines == 1 and s.col + #lines[1] or #lines[#lines]
	pcall(vim.api.nvim_win_set_cursor, 0, { last_row + 1, last_col })
end

function M.toggle()
	config.enabled = not config.enabled
	if not config.enabled then
		stop_timer()
		invalidate()
		stop_worker()
	end
	vim.notify("Claude autocomplete " .. (config.enabled and "on" or "off"))
end

function M.setup(opts)
	if vim.fn.executable("claude") == 0 then
		return
	end
	config = vim.tbl_deep_extend("force", config, opts or {})

	vim.api.nvim_set_hl(0, "ClaudeGhostText", { link = "Comment", default = true })

	local group = vim.api.nvim_create_augroup("claude-autocomplete", { clear = true })

	vim.api.nvim_create_autocmd("TextChangedI", {
		group = group,
		callback = function()
			invalidate()
			if not config.enabled or vim.bo.buftype ~= "" then
				return
			end
			stop_timer()
			timer = vim.fn.timer_start(config.debounce_ms, function()
				timer = nil
				M.trigger()
			end)
		end,
	})

	vim.api.nvim_create_autocmd("CursorMovedI", {
		group = group,
		callback = function()
			if suggestion then
				local pos = vim.api.nvim_win_get_cursor(0)
				if pos[1] - 1 ~= suggestion.row or pos[2] ~= suggestion.col then
					invalidate()
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = function()
			stop_timer()
			invalidate()
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = stop_worker,
	})

	vim.keymap.set("i", config.accept_key, M.accept, { desc = "Accept ghost completion" })
	vim.keymap.set("n", config.toggle_key, M.toggle, { desc = "[T]oggle [A]utocomplete" })
	vim.api.nvim_create_user_command("ClaudeCompleteToggle", M.toggle, {})
end

return M
