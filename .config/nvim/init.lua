-- Config begins here --

-- Tab and indentation settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Color column at 81 characters
vim.opt.colorcolumn = "81"
-- Highlight ColorColumn
vim.cmd([[highlight ColorColumn ctermbg=0]])

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
vim.o.updatetime = 250
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

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
--vim.g.mapleader = " "
--vim.g.maplocalleader = "\\"
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Keymaps begin here

-- Quickly switch buffers
vim.keymap.set("n", "<S-TAB>", ":bprevious<CR>")
vim.keymap.set("n", "<TAB>", ":bnext<CR>")
vim.keymap.set("n", "<leader>l", ":buffers<CR>")

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

require("config.lazy")

-- custom functions --

function SetDefaultTheme()
	-- color scheme code
	-- TODO
	local hour = tonumber(os.date("%H"))
	if hour > 17 or hour <= 5 then
		vim.cmd.colorscheme("kanagawa-wave")
	else
		vim.cmd.colorscheme("gruvbox")
		vim.g.gruvbox_invert_selection = 0
		vim.opt.background = "light"
	end
end

-- Diagnostic keymaps
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
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

vim.cmd([[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]])

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
-- the above)in Neovim. Syncs visual selection to * register without
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

vim.api.nvim_command("filetype plugin on")

SetDefaultTheme()
