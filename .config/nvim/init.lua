-- Config begins here --

vim.g.minimal_profile = vim.env.NVIM_MINIMAL == "1"

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

if not vim.g.minimal_profile then
	require("config.lazy")
end

-- Treesitter-based code folding
if not vim.g.minimal_profile then
	vim.opt.foldmethod = "expr"
	vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	vim.opt.foldenable = true
	vim.opt.foldlevel = 99
end

-- Keymaps --

-- Quickly switch buffers
-- vim.keymap.set("n", "<S-TAB>", ":bprevious<CR>", { desc = "Previous buffer" })
-- vim.keymap.set("n", "<TAB>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bd", ":%bd|e#|bd#<CR>", { desc = "Close all other buffers" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

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
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	print("Copied relative path: " .. path)
end, { desc = 'Copy relative path to "+' })

if not vim.g.minimal_profile then
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
	local map_float = function(buf_id, lhs)
		local rhs = function()
			-- Make a centered float the target window, then open the entry in it.
			-- The scratch buffer is wiped when go_in() replaces it with the file.
			local scratch = vim.api.nvim_create_buf(false, true)
			vim.bo[scratch].bufhidden = "wipe"
			local new_target = require("floatwin").open(scratch, { enter = false })
			MiniFiles.set_target_window(new_target)
			MiniFiles.go_in({ close_on_file = true })
			-- Focus the float once the explorer has closed (i.e. a file was opened)
			if MiniFiles.get_explorer_state() == nil and vim.api.nvim_win_is_valid(new_target) then
				vim.api.nvim_set_current_win(new_target)
			end
		end

		vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = "Open in float" })
	end
	vim.api.nvim_create_autocmd("User", {
		pattern = "MiniFilesBufferCreate",
		callback = function(args)
			local buf_id = args.data.buf_id
			-- Tweak keys to your liking
			map_split(buf_id, "<C-x>", "belowright horizontal")
			map_split(buf_id, "<C-v>", "belowright vertical")
			map_split(buf_id, "<C-t>", "tab")
			map_float(buf_id, "<C-f>")
		end,
	})

	local buffers = require("bufferpreview")
	buffers.setup_last_buffer_tracking()
	vim.keymap.set("n", "<leader><TAB>", function()
		vim.cmd.bnext()
		buffers.show_buffer_preview()
	end, { desc = "Next buffer" })
	vim.keymap.set("n", "<S-TAB>", function()
		vim.cmd.bprevious()
		buffers.show_buffer_preview()
	end, { desc = "Previous buffer" })
	vim.keymap.set("n", "<leader>l", buffers.switch_to_last_buffer, { desc = "Last buffer" })

	local term = require("term")
	vim.keymap.set("n", "<leader>tv", term.toggle_vsplit, { silent = true, desc = "Toggle terminal (v-split)" })
	vim.keymap.set("n", "<leader>tf", term.toggle_float, { silent = true, desc = "Toggle terminal (float)" })
end

-- Custom Functions --

local work_machine = false
if vim.fn.has("mac") == 1 then
	work_machine = true
end

local function use_terminal_background()
	local groups = {
		"Normal",
		"NormalNC",
		"EndOfBuffer",
		"SignColumn",
		"FoldColumn",
		"LineNr",
		"CursorLine",
		"CursorLineNr",
	}

	for _, group in ipairs(groups) do
		vim.cmd("highlight " .. group .. " ctermbg=NONE guibg=NONE")
	end
end

function SetDefaultTheme()
	if vim.g.minimal_profile then
		vim.cmd.colorscheme("default")
		use_terminal_background()
		return
	end

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

-- Session Management --

if not vim.g.minimal_profile then
	vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos"

	-- Sessions live in a central directory, keyed by project cwd
	-- (e.g. ~/.local/share/nvim/sessions/%Users%syed%Code%dotfiles.vim)
	local session_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "sessions")
	local function session_file_path(cwd)
		return vim.fs.joinpath(session_dir, (cwd:gsub("[\\/:]", "%%")) .. ".vim")
	end

	-- A session file is only real if it references at least one buffer
	-- (mksession writes a `badd` line per buffer); buffer-less sessions are
	-- treated as absent so they never block seeding or restore as a blank editor
	local function session_has_buffers(f)
		if vim.fn.filereadable(f) == 0 then
			return false
		end
		for _, line in ipairs(vim.fn.readfile(f)) do
			if line:match("^badd ") then
				return true
			end
		end
		return false
	end

	-- Every run in a project dir saves the session on exit ("last quit wins").
	-- A lock file (<session>.vim.lock holding the owner's PID) makes sure that
	-- while an instance is running in a project, one-off `nvim file` windows
	-- opened alongside it never overwrite its session: only the lock owner saves.
	local session_owner = false
	local owned_lock = nil

	local function pid_alive(pid)
		return pid ~= nil and vim.uv.kill(pid, 0) == 0
	end

	local function try_claim_session(cwd)
		local lock = session_file_path(cwd) .. ".lock"
		local ok, lines = pcall(vim.fn.readfile, lock)
		local owner_pid = ok and tonumber(lines[1] or "") or nil
		if owner_pid ~= vim.fn.getpid() and pid_alive(owner_pid) then
			return -- a live instance owns this project's session; stay secondary
		end
		vim.fn.mkdir(session_dir, "p")
		vim.fn.writefile({ tostring(vim.fn.getpid()) }, lock)
		session_owner = true
		owned_lock = lock
	end

	vim.api.nvim_create_autocmd("StdinReadPre", {
		callback = function()
			vim.g.started_with_stdin = true
		end,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		nested = true, -- so filetype detection, treesitter, and LSP attach to restored buffers
		callback = function()
			local cwd = vim.fn.getcwd()
			if vim.g.started_with_stdin or cwd == vim.env.HOME then
				return
			end
			try_claim_session(cwd)
			if vim.fn.argc() ~= 0 then
				return -- explicit files/dirs on the command line: don't restore
			end
			local f = session_file_path(cwd)

			-- Legacy per-project session (<cwd>/.nvim/session.vim): load it when
			-- no central session exists yet, then clean it up — the session gets
			-- saved to the central directory on exit
			local legacy_dir = vim.fs.joinpath(cwd, ".nvim")
			local legacy_file = vim.fs.joinpath(legacy_dir, "session.vim")
			local has_legacy = vim.fn.filereadable(legacy_file) == 1
			if has_legacy and not session_has_buffers(f) then
				f = legacy_file
			end

			if session_has_buffers(f) then
				local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(f))
				if not ok then
					vim.notify("Session restore failed: " .. err, vim.log.levels.WARN)
					return -- keep the legacy session around if restoring failed
				end
			end
			if has_legacy then
				vim.fn.delete(legacy_file)
				vim.uv.fs_rmdir(legacy_dir) -- succeeds only if the dir is now empty
			end
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			if not session_owner then
				return
			end
			-- Never save an empty session — quitting a blank editor must not
			-- poison the project's saved session
			local has_file_buf = false
			for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
				if b.name ~= "" and not b.name:match("^term://") then
					has_file_buf = true
					break
				end
			end
			local cwd = vim.fn.getcwd()
			if has_file_buf and cwd ~= vim.env.HOME then
				vim.fn.mkdir(session_dir, "p")
				local f = session_file_path(cwd)
				local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(f))
				if not ok then
					vim.notify("Session save failed: " .. err, vim.log.levels.WARN)
				end
			end
			vim.fn.delete(owned_lock)
		end,
	})
end

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
