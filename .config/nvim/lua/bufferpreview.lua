local M = {}

local preview_win
local preview_buf
local close_timer
local ns = vim.api.nvim_create_namespace("bufferpreview")
local current_buffer
local previous_buffer

local function close_preview()
	if close_timer then
		vim.fn.timer_stop(close_timer)
		close_timer = nil
	end

	if preview_win and vim.api.nvim_win_is_valid(preview_win) then
		vim.api.nvim_win_close(preview_win, true)
	end

	if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
		vim.api.nvim_buf_delete(preview_buf, { force = true })
	end

	preview_win = nil
	preview_buf = nil
end

local function display_width(lines)
	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end
	return width
end

local function is_tracked_buffer(bufnr)
	return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end

local function track_buffer(bufnr)
	if not is_tracked_buffer(bufnr) or bufnr == current_buffer then
		return
	end

	previous_buffer = current_buffer
	current_buffer = bufnr
end

function M.show_buffer_preview()
	close_preview()

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

	local max_visible = math.min(#infos, 21, math.max(1, vim.o.lines - 6))
	local half_window = math.floor(max_visible / 2)
	local start_i = math.max(1, cur_idx - half_window)
	local end_i = math.min(#infos, start_i + max_visible - 1)

	if end_i - start_i + 1 < max_visible then
		start_i = math.max(1, end_i - max_visible + 1)
	end

	local lines = {}
	local current_line
	for i = start_i, end_i do
		local b = infos[i]
		local name = (b.name ~= "" and vim.fn.fnamemodify(b.name, ":t")) or "[No Name]"
		local marker = b.bufnr == cur and "" or " "
		local modified = b.changed == 1 and "+" or " "
		local row = string.format("%s %3d %s %s", marker, b.bufnr, modified, name)

		if b.bufnr == cur then
			current_line = #lines
		end

		table.insert(lines, row)
	end

	local available_width = math.max(1, vim.o.columns - 8)
	local width = math.min(math.max(display_width(lines), 24), available_width)
	local col = math.max(0, math.floor((vim.o.columns - width) / 2))
	local row = math.max(0, math.floor((vim.o.lines - #lines) / 2))

	preview_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
	vim.bo[preview_buf].bufhidden = "wipe"
	vim.bo[preview_buf].modifiable = false

	preview_win = vim.api.nvim_open_win(preview_buf, false, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = #lines,
		style = "minimal",
		border = "rounded",
		focusable = false,
		zindex = 50,
	})

	vim.wo[preview_win].wrap = false
	vim.api.nvim_buf_clear_namespace(preview_buf, ns, 0, -1)
	if current_line then
		vim.api.nvim_buf_set_extmark(preview_buf, ns, current_line, 0, {
			line_hl_group = "Visual",
		})
	end

	close_timer = vim.fn.timer_start(500, function()
		vim.schedule(close_preview)
	end)
end

function M.switch_to_last_buffer()
	if not previous_buffer or not is_tracked_buffer(previous_buffer) then
		vim.notify("No previous buffer", vim.log.levels.INFO)
		return
	end

	vim.api.nvim_set_current_buf(previous_buffer)
	M.show_buffer_preview()
end

function M.setup_last_buffer_tracking()
	track_buffer(vim.api.nvim_get_current_buf())

	vim.api.nvim_create_autocmd("BufEnter", {
		group = vim.api.nvim_create_augroup("BufferPreviewLastBuffer", { clear = true }),
		callback = function(args)
			track_buffer(args.buf)
		end,
	})
end

return M
