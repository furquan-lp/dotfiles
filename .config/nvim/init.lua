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

-- Use mason instead
--
-- Setup language servers.
--local lspconfig = require('lspconfig')
--vim.lsp.config('pylsp', {
--    on_attach = custom_attach,
--    settings = {
--        pylsp = {
--            plugins = {
--                pycodestyle = {
--                    ignore = { 'W391' },
--                    maxLineLength = 120
--                },
--                pylsp_mypy = { enabled = true },
--                jedi_completion = {
--                    enabled = true,
--                    fuzzy = true
--                },
--                pyls_isort = { enabled = true },
--                rope_autoimport = { enabled = true },
--            },
--        },
--    },
--    flags = {
--        debounce_text_changes = 200,
--    },
--})
--vim.lsp.enable('pylsp')
--vim.lsp.enable('ts_ls')

-- Configured in plugins.lua
--
-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
--vim.api.nvim_create_autocmd("LspAttach", {
--    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
--    callback = function(ev)
--        -- Enable completion triggered by <c-x><c-o>
--        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
--
--        -- Buffer local mappings.
--        -- See `:help vim.lsp.*` for documentation on any of the below functions
--        local opts = { buffer = ev.buf }
--        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
--        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
--        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
--        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
--        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
--        vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
--        vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
--        vim.keymap.set("n", "<space>wl", function()
--            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
--        end, opts)
--        vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
--        vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
--        vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
--        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
--        vim.keymap.set("n", "<space>f", function()
--            vim.lsp.buf.format({ async = true })
--        end, opts)
--    end,
--})

-- custom functions --

function SetDefaultTheme()
	-- color scheme code
	-- TODO
	local hour = tonumber(os.date("%H"))
	if hour > 17 or hour <= 5 then
		vim.cmd.colorscheme("kanagawa-wave")
	else
		vim.cmd.colorscheme("kanagawa-lotus")
		-- vim.g.gruvbox_invert_selection = 0
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

-- vim.api.nvim_set_keymap('v', '<Esc>', [[<Esc>`>a]] .. 'gv"*ygv', {noremap = true, silent = true})
vim.api.nvim_create_autocmd("CursorMoved", {
	desc = "Keep * synced with selection",
	callback = function()
		local mode = vim.fn.mode(false)
		if mode == "v" or mode == "V" or mode == "\22" then
			vim.cmd([[silent norm "*ygv]])
		end
	end,
})

vim.api.nvim_command("filetype plugin on")

SetDefaultTheme()
