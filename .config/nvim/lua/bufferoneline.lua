local M = {}

function M.show_buffers_one_line()
	local cur = vim.api.nvim_get_current_buf()
	local infos = vim.fn.getbufinfo({ buflisted = 1 })

	local cur_idx
	for i, b in ipairs(infos) do
		if b.bufnr == cur then
			cur_idx = i
			break
		end
	end
	if not cur_idx then
		return
	end

	-- window range: 2 left, 2 right
	local start_i = math.max(1, cur_idx - 2)
	local end_i = math.min(#infos, cur_idx + 2)

	-- nerd-font marker for current
	local marker = ""

	local parts = {}
	for i = start_i, end_i do
		local b = infos[i]
		local name = (b.name ~= "" and vim.fn.fnamemodify(b.name, ":t")) or "[No Name]"

		local fmt
		if b.bufnr == cur then
			-- show marker + buf number + name
			fmt = string.format("%s%d:%s", marker, b.bufnr, name)
		else
			-- only name
			fmt = name
		end

		table.insert(parts, fmt)
	end
	vim.api.nvim_echo({ { table.concat(parts, "  |  ") } }, false, {})
end

return M
