-- Per-project session management.
--
-- Sessions live in a central directory, keyed by project cwd
-- (e.g. ~/.local/share/nvim/sessions/%Users%syed%Code%dotfiles.vim).
-- Every run in a project dir saves the session on exit ("last quit wins").
-- A lock file (<session>.vim.lock holding the owner's PID) makes sure that
-- while an instance is running in a project, one-off `nvim file` windows
-- opened alongside it never overwrite its session: only the lock owner saves.
-- Restore only happens on a bare `nvim` (no file/dir arguments, no stdin).

local M = {}

local session_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "sessions")

local function session_file_path(cwd)
	return vim.fs.joinpath(session_dir, (cwd:gsub("[\\/:]", "%%")) .. ".vim")
end

-- A session file is only real if it references at least one buffer
-- (mksession writes a `badd` line per buffer); buffer-less sessions are
-- treated as absent so they never block saving or restore as a blank editor
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

local function restore()
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
end

local function save()
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
end

function M.setup()
	vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos"

	vim.api.nvim_create_autocmd("StdinReadPre", {
		callback = function()
			vim.g.started_with_stdin = true
		end,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		nested = true, -- so filetype detection, treesitter, and LSP attach to restored buffers
		callback = restore,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = save,
	})
end

return M
