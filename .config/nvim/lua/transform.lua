-- AI selection transform (Cursor Cmd-K style) via OpenRouter.
--
-- Select lines in visual mode, hit <leader>ai, type an instruction into the
-- small floating prompt, and the selected lines are rewritten in place by
-- GPT-5.6 Luna with reasoning off. Chosen by bench/transform: within a
-- quarter point of the best judged quality, zero output-hygiene failures
-- across 117 calls, ~1.6 s median round trip, ~$0.0002 per call.
-- The whole file is sent as context (trimmed to a window around the
-- selection only past a size ceiling). Each transform is one non-streaming
-- curl; the API key travels via the environment, never argv. The
-- replacement is applied as a single undo step; `u` reverts it. Selections
-- operate on whole lines.

local M = {}

local ns = vim.api.nvim_create_namespace("ai_transform")

local config = {
	trigger_key = "<leader>ai",
	url = "https://openrouter.ai/api/v1/chat/completions",
	secret = vim.fn.expand("~/.config/llm/secrets/openrouter"),
	model = "openai/gpt-5.6-luna",
	reasoning = { effort = "none" },
	-- Bedrock had the lowest latency in the benchmark; the other Luna hosts
	-- are fallbacks so an outage on one endpoint doesn't disable the feature
	provider = { order = { "amazon-bedrock/us-east-1", "openai" }, allow_fallbacks = true },
	max_tokens = 4096,
	-- The whole file goes along as context: bench/transform/context_bench showed
	-- it costs ~0.1 s and fixes every edit that depends on a definition far from
	-- the selection. Above this many characters of context (~12K tokens) the
	-- file is trimmed to a window around the selection instead.
	max_context_chars = 48000,
	timeout_ms = 60000,
}

-- Sectioned developer message per OpenAI's GPT-5.6 prompting guide: each
-- rule stated once, output contract last
local system_prompt = table.concat({
	"# Role",
	"You rewrite code selections for an editor.",
	"",
	"# Input",
	"The user message contains the file name, language, the code before and after the selection,",
	"the selection inside <selection> tags, and an instruction at the end.",
	"",
	"# Constraints",
	"- Only make the changes the instruction asks for. Do not add comments, docstrings, type hints, or refactors to code you were not asked to change.",
	"- Keep the selection's leading indentation and indentation style unless the instruction says otherwise.",
	"- If the instruction cannot be applied to the selection, return the selection unchanged.",
	"",
	"# Output",
	"Only the replacement text for the code inside the <selection> tags, ready to be inserted in place of those lines.",
	"Start directly with the code. No preamble, no markdown fences, no commentary, no tags.",
}, "\n")

local running = nil -- vim.system handle of the in-flight transform
local api_key = nil

local function read_secret()
	if api_key == nil then
		local f = io.open(config.secret, "r")
		if f then
			api_key = vim.trim(f:read("*a"))
			f:close()
		else
			api_key = false
		end
	end
	return api_key or nil
end

-- Keep the whole file when it fits the budget; otherwise grow a window outward
-- from the selection, one line from each side in turn, until the budget is spent
local function fit_context(before, after, budget)
	local total = 0
	for _, l in ipairs(before) do
		total = total + #l + 1
	end
	for _, l in ipairs(after) do
		total = total + #l + 1
	end
	if total <= budget then
		return before, after
	end
	local b, a = {}, {}
	local bi, ai = #before, 1
	local used = 0
	while bi >= 1 or ai <= #after do
		if bi >= 1 then
			local l = before[bi]
			if used + #l + 1 > budget then
				break
			end
			table.insert(b, 1, l)
			used = used + #l + 1
			bi = bi - 1
		end
		if ai <= #after then
			local l = after[ai]
			if used + #l + 1 > budget then
				break
			end
			a[#a + 1] = l
			used = used + #l + 1
			ai = ai + 1
		end
	end
	return b, a
end

local function clear_progress(bufnr)
	if vim.api.nvim_buf_is_valid(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	end
end

-- Pull the replacement text out of a chat completion, or return nil + reason
local function parse_response(stdout)
	local ok, body = pcall(vim.json.decode, stdout or "")
	if not ok or type(body) ~= "table" then
		return nil, "unreadable response"
	end
	if body.error then
		return nil, type(body.error) == "table" and (body.error.message or vim.inspect(body.error)) or tostring(body.error)
	end
	local choice = body.choices and body.choices[1]
	local text = choice and choice.message and choice.message.content
	if type(text) ~= "string" then
		return nil, "no content in response"
	end
	-- Trim only surrounding newlines/trailing whitespace so indentation survives
	return (text:gsub("^\n+", ""):gsub("%s+$", ""))
end

-- srow/erow are 1-based, inclusive
function M.transform_lines(bufnr, srow, erow, instruction)
	local key = read_secret()
	if not key then
		vim.notify("AI transform: no API key at " .. config.secret, vim.log.levels.WARN)
		return
	end
	if running then
		running:kill(15) -- a new request supersedes the previous one
		running = nil
	end

	local before = vim.api.nvim_buf_get_lines(bufnr, 0, srow - 1, false)
	local selection = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
	local after = vim.api.nvim_buf_get_lines(bufnr, erow, -1, false)
	before, after = fit_context(before, after, config.max_context_chars)
	local name = vim.api.nvim_buf_get_name(bufnr)

	local payload = ("File: %s\nLanguage: %s\n\n<code_before>\n%s\n</code_before>\n<selection>\n%s\n</selection>\n<code_after>\n%s\n</code_after>\n\nInstruction: %s"):format(
		name ~= "" and vim.fn.fnamemodify(name, ":t") or "(unnamed)",
		vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or "unknown",
		table.concat(before, "\n"),
		table.concat(selection, "\n"),
		table.concat(after, "\n"),
		instruction
	)

	local body = vim.json.encode({
		model = config.model,
		messages = {
			{ role = "system", content = system_prompt },
			{ role = "user", content = payload },
		},
		reasoning = config.reasoning,
		provider = config.provider,
		max_tokens = config.max_tokens,
	})

	-- If the buffer changes while the model works, the range is stale and
	-- the result must not be applied
	local tick = vim.b[bufnr].changedtick

	clear_progress(bufnr)
	vim.api.nvim_buf_set_extmark(bufnr, ns, srow - 1, 0, {
		virt_text = { { "⟳ AI transforming…", "DiagnosticVirtualTextInfo" } },
		virt_text_pos = "eol",
	})

	running = vim.system({
		"sh",
		"-c",
		'exec curl -sS --fail-with-body --max-time ' .. math.ceil(config.timeout_ms / 1000) .. ' -X POST "$AI_URL" '
			.. '-H "Content-Type: application/json" -H "Authorization: Bearer $AI_KEY" '
			.. "--data-binary @-",
	}, {
		stdin = body,
		env = { AI_URL = config.url, AI_KEY = key },
		timeout = config.timeout_ms,
	}, function(out)
		vim.schedule(function()
			running = nil
			clear_progress(bufnr)
			local text, err = parse_response(out.stdout)
			if not text then
				if out.code ~= 0 and (not err or err == "unreadable response") then
					err = vim.trim(out.stderr or "")
					err = err ~= "" and err or ("exit code " .. out.code)
				end
				vim.notify("AI transform failed: " .. err, vim.log.levels.WARN)
				return
			end
			if text == "" then
				vim.notify("AI transform returned nothing; selection left unchanged", vim.log.levels.WARN)
				return
			end
			if not vim.api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].changedtick ~= tick then
				vim.notify("Buffer changed during AI transform; result discarded", vim.log.levels.WARN)
				return
			end
			vim.api.nvim_buf_set_lines(bufnr, srow - 1, erow, false, vim.split(text, "\n", { plain = true }))
			vim.notify("AI transform applied (u to undo)")
		end)
	end)
end

-- Small floating input anchored at the cursor; <CR> submits, <Esc> cancels
local function prompt_float(on_submit)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buftype = "prompt"
	vim.fn.prompt_setprompt(buf, "> ")
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		row = 1,
		col = 0,
		width = math.min(60, vim.o.columns - 4),
		height = 1,
		style = "minimal",
		border = "rounded",
		title = " AI transform ",
		title_pos = "center",
	})
	local function close()
		vim.cmd.stopinsert()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	vim.fn.prompt_setcallback(buf, function(text)
		close()
		text = vim.trim(text)
		if text ~= "" then
			on_submit(text)
		end
	end)
	vim.keymap.set({ "n", "i" }, "<Esc>", close, { buffer = buf })
	vim.cmd.startinsert()
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	if vim.fn.executable("curl") == 0 or vim.fn.filereadable(config.secret) == 0 then
		return
	end

	vim.keymap.set("x", config.trigger_key, function()
		local bufnr = vim.api.nvim_get_current_buf()
		local srow, erow = vim.fn.line("v"), vim.fn.line(".")
		if srow > erow then
			srow, erow = erow, srow
		end
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
		prompt_float(function(instruction)
			M.transform_lines(bufnr, srow, erow, instruction)
		end)
	end, { desc = "[A]I transform selection" })
end

return M
