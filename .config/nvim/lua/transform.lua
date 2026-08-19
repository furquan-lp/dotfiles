-- AI selection transform (Cursor Cmd-K style) via the Claude Code CLI.
--
-- Select lines in visual mode, hit <leader>ai, type an instruction into the
-- small floating prompt, and the selected lines are rewritten in place by
-- haiku with extended thinking left ON (quality over latency here - unlike
-- autocomplete, which disables it via MAX_THINKING_TOKENS=0). Haiku has no
-- graded effort levels: thinking on/off is the only knob that does anything,
-- so no --effort flag is passed.
-- Each transform is a one-shot `claude -p` call: transforms are infrequent
-- and deliberate, so process startup doesn't matter, and a fresh process
-- can't leak history between requests. The replacement is applied as a
-- single undo step; `u` reverts it. Selections operate on whole lines.

local M = {}

local ns = vim.api.nvim_create_namespace("claude_transform")

local config = {
	trigger_key = "<leader>ai",
	model = "haiku",
	context_lines = 30, -- lines of context on each side of the selection
	timeout_ms = 90000,
}

local system_prompt = table.concat({
	"You rewrite code selections.",
	"The user message contains code from a file and an instruction.",
	"Output ONLY the replacement for the code inside the <selection> tags:",
	"raw text ready to be inserted in place of those lines.",
	"No explanation, no markdown fences, no commentary, no tags.",
	"Preserve the selection's leading indentation unless asked otherwise.",
	"If the instruction cannot be applied, output the selection unchanged.",
}, " ")

local running = nil -- vim.system handle of the in-flight transform

local function clear_progress(bufnr)
	if vim.api.nvim_buf_is_valid(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	end
end

-- srow/erow are 1-based, inclusive
function M.transform_lines(bufnr, srow, erow, instruction)
	if running then
		running:kill(15) -- a new request supersedes the previous one
		running = nil
	end

	local before_start = math.max(0, srow - 1 - config.context_lines)
	local before = vim.api.nvim_buf_get_lines(bufnr, before_start, srow - 1, false)
	local selection = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
	local after = vim.api.nvim_buf_get_lines(bufnr, erow, erow + config.context_lines, false)
	local name = vim.api.nvim_buf_get_name(bufnr)

	local payload = ("File: %s\nLanguage: %s\n\n<code_before>\n%s\n</code_before>\n<selection>\n%s\n</selection>\n<code_after>\n%s\n</code_after>\n\nInstruction: %s"):format(
		name ~= "" and vim.fn.fnamemodify(name, ":t") or "(unnamed)",
		vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or "unknown",
		table.concat(before, "\n"),
		table.concat(selection, "\n"),
		table.concat(after, "\n"),
		instruction
	)

	-- If the buffer changes while the model works, the range is stale and
	-- the result must not be applied
	local tick = vim.b[bufnr].changedtick

	clear_progress(bufnr)
	vim.api.nvim_buf_set_extmark(bufnr, ns, srow - 1, 0, {
		virt_text = { { "⟳ AI transforming…", "DiagnosticVirtualTextInfo" } },
		virt_text_pos = "eol",
	})

	running = vim.system({
		"claude",
		"-p",
		"--model",
		config.model,
		"--strict-mcp-config",
		"--system-prompt",
		system_prompt,
		"--tools",
		"",
		"--no-session-persistence",
		"--disable-slash-commands",
		"--setting-sources",
		"",
	}, { stdin = payload, timeout = config.timeout_ms }, function(out)
		vim.schedule(function()
			running = nil
			clear_progress(bufnr)
			if out.code ~= 0 then
				local err = vim.trim(out.stderr or "")
				vim.notify("AI transform failed: " .. (err ~= "" and err or ("exit code " .. out.code)), vim.log.levels.WARN)
				return
			end
			-- Strip stray fences; trim only newlines so indentation survives
			local text = require("autocomplete")._strip_fences((out.stdout or ""):gsub("^\n+", ""):gsub("%s+$", ""))
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
	if vim.fn.executable("claude") == 0 then
		return
	end
	config = vim.tbl_deep_extend("force", config, opts or {})

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
