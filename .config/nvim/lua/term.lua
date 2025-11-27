local M = {}

local term_buf = nil -- terminal buffer
local float_win = nil -- floating window handle
local term_job = nil -- terminal job id

local function is_job_running(job_id)
	if not job_id then
		return false
	end
	-- jobwait({id}, 0) returns -1 if the job is still running
	local status = vim.fn.jobwait({ job_id }, 0)[1]
	return status == -1
end

local function ensure_term()
	-- Reuse existing terminal buffer if it's valid and the job is still running
	if term_buf and vim.api.nvim_buf_is_valid(term_buf) and is_job_running(term_job) then
		return term_buf
	end

	-- (Re)create the buffer if needed
	if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
		term_buf = vim.api.nvim_create_buf(false, true)
	else
		-- Clear old contents if we're reusing the buffer after the job exited
		vim.api.nvim_buf_set_lines(term_buf, 0, -1, false, {})
	end

	-- Keep the buffer around but hide it when no window is using it
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = term_buf })

	-- Start a new terminal job in this buffer without creating a window
	vim.api.nvim_buf_call(term_buf, function()
		term_job = vim.fn.jobstart(vim.o.shell, {
			term = true, -- make this a terminal attached to the current buffer
			on_exit = function()
				term_job = nil
			end,
		})
	end)

	return term_buf
end

local function set_term_window_options(win)
	-- Ensure a clean terminal look regardless of global/window settings
	vim.api.nvim_set_option_value("number", false, { scope = "local", win = win })
	vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = win })
	vim.api.nvim_set_option_value("cursorline", false, { scope = "local", win = win })
	vim.api.nvim_set_option_value("signcolumn", "no", { scope = "local", win = win })
	vim.api.nvim_set_option_value("foldcolumn", "0", { scope = "local", win = win })
end

-- Toggle as vertical split
function M.toggle_vsplit()
	local buf = ensure_term()

	local win = vim.fn.bufwinnr(buf)
	if win ~= -1 then
		-- buffer is visible somewhere: close that window
		vim.cmd(win .. "wincmd c")
	else
		-- reopen in a vsplit
		vim.cmd("botright vsplit")
		local cur_win = vim.api.nvim_get_current_win()
		vim.api.nvim_set_current_buf(buf)
		set_term_window_options(cur_win)
		vim.cmd("startinsert")
	end
end

-- Toggle as floating window
function M.toggle_float()
	local buf = ensure_term()

	if float_win and vim.api.nvim_win_is_valid(float_win) then
		vim.api.nvim_win_close(float_win, true)
		float_win = nil
		return
	end

	local width = math.floor(vim.o.columns * 0.5)
	local height = math.floor(vim.o.lines * 0.5)

	float_win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = (vim.o.lines - height) / 2,
		col = (vim.o.columns - width) / 2,
		style = "minimal",
		border = "rounded",
	})

	set_term_window_options(float_win)
	vim.cmd("startinsert")
end

return M
