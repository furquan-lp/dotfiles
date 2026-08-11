local M = {}

-- Open a centered floating window (50% x 80% of the editor) showing `buf`
function M.open(buf, opts)
	opts = opts or {}
	local width = math.floor(vim.o.columns * 0.5)
	local height = math.floor(vim.o.lines * 0.8)
	return vim.api.nvim_open_win(buf, opts.enter ~= false, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		border = "rounded",
	})
end

return M
