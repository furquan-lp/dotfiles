-- Config begins here --

-- Tab and indentation settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- netrw settings
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
-- Don't move cursor to beginning of line
vim.opt.startofline = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.hlsearch = true
vim.opt.linebreak = true
-- 24-bit color
vim.opt.termguicolors = true
-- Color column at 81 characters
vim.opt.colorcolumn = { "81", "121" }
-- Highlight ColorColumn (Don't use, set by the colorscheme)
-- vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 0, bg = "#2E3440" })

vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Keymaps begin here

-- Quickly switch buffers
-- vim.keymap.set("n", "<S-TAB>", ":bprevious<CR>", { desc = "Previous buffer" })
-- vim.keymap.set("n", "<TAB>", ":bnext<CR>", { desc = "Next buffer" })
-- vim.keymap.set("n", "<leader>l", ":buffers<CR>") -- No need with Telescope
vim.keymap.set("n", "<leader>bd", ":%bd|e#<CR>", { desc = "Close all other buffers" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

require("config.lazy")

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.keymap.set("n", "<leader>yp", function()
	vim.fn.setreg("+", vim.fn.expand("%"))
	print("Copied relative path: " .. vim.fn.expand("%"))
end, { desc = 'Copy relative path to "+' })

vim.keymap.set("n", "<leader>gb", function()
	require("gitsigns").blame_line({ full = true })
end, { desc = "Blame line (popup)" })
vim.keymap.set("n", "<leader>gd", require("gitsigns").preview_hunk, { desc = "Preview git hunk" })

local MiniFiles = require("mini.files")
local map_split = function(buf_id, lhs, direction)
	local rhs = function()
		-- Make new window and set it as target
		local cur_target = MiniFiles.get_explorer_state().target_window
		local new_target = vim.api.nvim_win_call(cur_target, function()
			vim.cmd(direction .. " split")
			return vim.api.nvim_get_current_win()
		end)

		MiniFiles.set_target_window(new_target)
		MiniFiles.go_in()
	end

	local desc = "Split " .. direction
	vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
end
vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesBufferCreate",
	callback = function(args)
		local buf_id = args.data.buf_id
		-- Tweak keys to your liking
		map_split(buf_id, "<C-x>", "belowright horizontal")
		map_split(buf_id, "<C-v>", "belowright vertical")
		map_split(buf_id, "<C-t>", "tab")
	end,
})

local function show_buffers_one_line()
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
vim.keymap.set("n", "<leader><TAB>", function()
	vim.cmd.bnext()
	show_buffers_one_line()
end, { desc = "Next buffer" })
vim.keymap.set("n", "<S-TAB>", function()
	vim.cmd.bprevious()
	show_buffers_one_line()
end, { desc = "Previous buffer" })

-- custom functions --

local work_machine = false
if vim.fn.has("mac") == 1 then
	work_machine = true
end

function SetDefaultTheme()
	-- color scheme code
	local hour = tonumber(os.date("%H"))
	local dark_theme = "kanagawa-wave"
	local light_theme = "gruvbox"
	local work_theme = "nord"
	if work_machine then
		vim.cmd.colorscheme(work_theme)
	elseif hour > 17 or hour <= 5 then
		vim.cmd.colorscheme(dark_theme)
	else
		vim.cmd.colorscheme(light_theme)
		vim.opt.background = "light"
	end
end

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Restore cursor position when reopening files (excluding git commit/rebase)
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function()
		local ft = vim.bo.filetype
		if not ft:match("commit") and not ft:match("rebase") then
			local last_pos = vim.fn.line([['"]])
			if last_pos > 1 and last_pos <= vim.fn.line("$") then
				vim.cmd([[normal! g`"]])
			end
		end
	end,
})

-- Session Management

vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Per-project session file: <project>/.nvim/session.vim
local function session_file()
	local cwd = vim.fn.getcwd()
	local sdir = cwd .. "/.nvim"
	vim.fn.mkdir(sdir, "p")
	return sdir .. "/session.vim"
end

-- Save session when exiting (e.g., last :q, :qa, closing terminal)
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		local f = session_file()
		vim.cmd("silent! mksession! " .. vim.fn.fnameescape(f))
	end,
})

-- Load session when starting in a project dir with no files specified
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then -- don't override if you opened specific files
			local f = session_file()
			if vim.fn.filereadable(f) == 1 then
				vim.cmd("silent! source " .. vim.fn.fnameescape(f))
			end
		end
	end,
})

---- vim.api.nvim_set_keymap('v', '<Esc>', [[<Esc>`>a]] .. 'gv"*ygv', {noremap = true, silent = true})
--vim.api.nvim_create_autocmd("CursorMoved", {
--	desc = "Keep * synced with selection",
--	callback = function()
--		local mode = vim.fn.mode(false)
--		if mode == "v" or mode == "V" or mode == "\22" then
--			vim.cmd([[silent norm "*ygv]])
--		end
--	end,
--})

-- Debounced solution for clipboard=autoselect behavior workaround (similar to
-- the above) in Neovim. Syncs visual selection to * register without
-- interfering with which-key/mini.clue
local timer = nil

local function sync_selection()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local start_pos = vim.fn.getpos("v")
		local end_pos = vim.fn.getpos(".")
		local lines = vim.fn.getregion(start_pos, end_pos, { type = mode })
		vim.fn.setreg("*", table.concat(lines, "\n"))
	end
end

if not work_machine then
	vim.api.nvim_create_autocmd("CursorMoved", {
		desc = "Keep * register synced with visual selection (debounced)",
		callback = function()
			local mode = vim.fn.mode()
			if mode == "v" or mode == "V" or mode == "\22" then
				-- Cancel previous timer
				if timer then
					vim.fn.timer_stop(timer)
				end
				-- Only sync after 200ms of no cursor movement
				timer = vim.fn.timer_start(200, sync_selection)
			end
		end,
	})
end

SetDefaultTheme()
