# Syed's Dotfiles

## My Neovim Cheatsheet

**Leader Key:** `,`

### Profiles

The default `nvim` command loads the full editing profile with plugins, LSP, Telescope, completion, formatting, git signs, UI helpers, and per-project sessions.

Use the minimal profile when you want a calmer editor with the shared core settings but without plugin-backed features, Lazy startup, or per-project session save/restore:

```sh
NVIM_MINIMAL=1 nvim
nvi
svim /etc/some-file
```

`svim` uses `sudoedit` with `$HOME/.local/bin/nvim`, so Neovim runs as your user while `sudoedit` writes the file back with elevated permissions.

Git is configured to use the same minimal profile for commit messages:

```ini
[core]
	editor = env NVIM_MINIMAL=1 nvim
```

### Sessions (Full Profile)

Launching a bare `nvim` in a project directory restores that project's session. Sessions are stored centrally in `~/.local/share/nvim/sessions/`, keyed by the project path.

* Saving is "last quit wins": every run — bare or with file arguments — saves the session on exit. The exception: while an instance is running in a project, it owns the session (via a `.lock` file holding its PID; stale locks from crashes are taken over), and one-off `nvim file` windows opened alongside it don't save on exit.
* Opening specific files (`nvim path/to/file` or `nvim .`) never *restores* the session — restore only happens on a bare `nvim`.
* Piping stdin skips sessions entirely, and no sessions are saved for `$HOME` itself.
* Empty sessions are never saved: quitting a blank editor doesn't overwrite the project's session, and a session file without buffers is treated as absent (it doesn't block seeding and won't restore a blank editor).
* Legacy `<project>/.nvim/session.vim` files migrate automatically: the old session is loaded once, then deleted (the `.nvim` directory is removed if that leaves it empty).

### Colorschemes

The theme is picked automatically at startup:

* On a Mac (treated as the work machine): `nord`.
* Otherwise, `kanagawa-wave` after 5pm and before 6am, `gruvbox` (light) during the day.
* Minimal profile: the built-in `default` scheme with a transparent background, so the terminal's background shows through.

### Automatic Behaviors

* **Treesitter folding (full profile)**: `foldmethod=expr` with the treesitter fold expression; all folds start open (`foldlevel=99`).
* **Cursor position restore**: reopening a file jumps to the last cursor position (skipped for git commit/rebase buffers).
* **Yank highlight**: yanked text flashes briefly.
* **Visual selection → `*` register (non-work machines)**: the visual selection is synced to the `*` register after 200ms of no cursor movement, approximating `clipboard=autoselect`.

---

### **General & Editor**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<Esc>` | Normal | Clears search highlighting. |
| `<C-h>` | Normal | Move focus to the left window. |
| `<C-l>` | Normal | Move focus to the right window. |
| `<C-j>` | Normal | Move focus to the lower window. |
| `<C-k>` | Normal | Move focus to the upper window. |
| `<leader>c` | Normal | Full profile: toggle treesitter context between compact (one line per scope) and full multiline. |

---

### **Buffers & Files**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<leader><TAB>` | Normal | Full profile: go to the next buffer and show a floating buffer-list preview (auto-closes after 500ms). |
| `<S-TAB>` | Normal | Full profile: go to the previous buffer and show the floating buffer-list preview. |
| `<leader>l` | Normal | Full profile: switch to the **l**ast buffer (most recently visited). |
| `<leader>bd` | Normal | Close all other buffers, keeping only the current one. |
| `<leader>E` | Normal | Full profile: toggle the `mini.files` file explorer. |
| `<leader>yp` | Normal | Copy the current file's **relative path** to the system clipboard. |

Inside the `mini.files` explorer:

| Keymap | Description |
| --- | --- |
| `<C-x>` | Open the entry in a horizontal split. |
| `<C-v>` | Open the entry in a vertical split. |
| `<C-t>` | Open the entry in a new tab. |
| `<C-f>` | Open the entry in a centered floating window (closes the explorer). |

---

### **Terminal**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<Esc><Esc>` | Terminal | Exit terminal mode and return to Normal mode. |
| `<leader>tv` | Normal | Full profile: toggle a terminal in a vertical split. |
| `<leader>tf` | Normal | Full profile: toggle a terminal in a centered floating window. |

---

### **Search (Telescope, Full Profile)**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<leader>sf` | Normal | **S**earch **F**iles (respects .gitignore). |
| `<leader>sg` | Normal | **S**earch by **G**rep (live grep) in your project. |
| `<leader>sw` | Normal | **S**earch for the current **W**ord under the cursor. |
| `<leader>s/` | Normal | **S**earch by Grep in currently open files. |
| `<leader>sp` | Normal | **S**earch in a chosen **P**ath (live grep in a specified directory). |
| `<leader>/` | Normal | Fuzzily search within the current buffer. |
| `<leader>sh` | Normal | **S**earch **H**elp tags. |
| `<leader>sk` | Normal | **S**earch **K**eymaps. |
| `<leader>sd` | Normal | **S**earch **D**iagnostics (LSP errors, warnings). |
| `<leader>ss` | Normal | **S**earch **S**elect a Telescope picker. |
| `<leader>sr` | Normal | **S**earch **R**esume last Telescope search. |
| `<leader>s.` | Normal | **S**earch **R**ecent files (oldfiles). |
| `<leader>sn` | Normal | **S**earch **N**eovim config files. |
| `<leader><leader>` | Normal | Find existing buffers. In the picker, `<C-d>` (insert mode) or `dd` (normal mode) deletes the selected buffer. |

Inside any picker, `<C-x>` / `<C-v>` / `<C-t>` (Telescope defaults) open the selection in a horizontal split, vertical split, or new tab, and `<C-f>` opens it in a centered floating window (entries without a file path fall back to the default action).

---

### **Editing & Text Objects (Full Profile)**

These actions come from `mini.nvim`.

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| **Commenting** (`mini.comment`) |
| `gcc` | Normal | Toggles the comment state for the current line. |
| `gc` | Normal / Visual | Toggles comments for the motion or visual selection (e.g., `gcip` for inner paragraph). |
| **Surrounding** (`mini.surround`) |
| `sa<char>` | Normal / Visual | **A**dd **s**urrounding `<char>` (e.g., `saw"` adds quotes around a word). |
| `sd<char>` | Normal | **D**elete **s**urrounding `<char>` (e.g., `sd"` deletes surrounding quotes). |
| `sr<from><to>` | Normal | **R**eplace **s**urrounding `<from>` char with `<to>` char (e.g., `sr'"` replaces single quotes with double). |

---

### **LSP (Language Server Protocol, Full Profile)**

These keymaps are available when an LSP server is attached to a buffer. The `g` prefix is for "goto", and `gr` is a common convention.

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `grn` | Normal | **R**e**n**ame the symbol under the cursor. |
| `gra` | Normal / Visual | Trigger a code **A**ction. |
| `grr` | Normal | Go to **R**eferences (via Telescope). |
| `gri` | Normal | Go to **I**mplementation (via Telescope). |
| `grd` | Normal | Go to **D**efinition (via Telescope). |
| `grv` | Normal | Go to Definition in a **v**ertical split. |
| `grx` | Normal | Go to Definition in a horizontal split. |
| `grp` | Normal | **P**eek the definition in a small float at the cursor; leaving the float (window nav, `:q`) closes it. |
| `grD` | Normal | Go to **D**eclaration. |
| `grt` | Normal | Go to **T**ype **D**efinition (via Telescope). |
| `gO` | Normal | Show d**O**cument symbols (via Telescope). |
| `gW` | Normal | Show **W**orkspace symbols (via Telescope). |

---

### **Diagnostics**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `[d` | Normal | Go to the previous diagnostic message. |
| `]d` | Normal | Go to the next diagnostic message. |
| `<leader>e` | Normal | Show diagnostic **E**rror messages in a floating window. |
| `<leader>q` | Normal | Open diagnostics in the location list. |
| `<leader>sd` | Normal | Full profile: [Telescope] **S**earch **D**iagnostics. |

---

### **Autocompletion (`blink.cmp` with super-tab preset, Full Profile)**

These keymaps are active in **Insert Mode** when the completion menu is visible.

| Keymap | Mode | Description |
| --- | --- | --- |
| `<Tab>` | Insert | Select the next item / If a snippet is active, move to the next placeholder / Accept selection. |
| `<S-Tab>` | Insert | Select the previous item / If a snippet is active, move to the previous placeholder. |
| `<C-Space>` | Insert | Manually open the completion menu. |
| `<C-e>` | Insert | Hide the completion menu. |
| `<C-n>` / `<Down>` | Insert | Select the next item in the menu. |
| `<C-p>` / `<Up>` | Insert | Select the previous item in the menu. |
| `<C-k>` | Insert | Toggle signature help window. |

---

### **Formatting (`conform.nvim`, Full Profile)**

Buffers are also formatted automatically on save (1s timeout, falling back to the LSP formatter), except for C/C++ files.

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<leader>f` | Normal / Visual | **F**ormat the buffer or selection. |

---

### **Git (`gitsigns.nvim`, Full Profile)**

Current-line git blame annotations are enabled by default (1s delay, end of line).

| Command/Key | Mode(s) | Description |
| --- | --- | --- |
| `<leader>gb` | Normal | Show a detailed git blame popup for the current line. |
| `<leader>gd` | Normal | Preview the current git hunk in a floating window. |
| `:Gitsigns toggle_current_line_blame` | Command | Toggle the git blame annotation for the current line. |
| `:Gitsigns nav_hunk next` / `:Gitsigns nav_hunk prev` | Command | Jump between hunks (no keymaps are configured for hunk navigation). |

---

### **Plugin-Provided Features (No Keymaps, Full Profile)**

*   **guess-indent.nvim**: Automatically detects and sets indentation settings per file.
*   **mini.indentscope**: Provides visual guides for indentation levels.
*   **mini.trailspace**: Highlights trailing whitespace. Removal is left to the formatter, which runs on save; `:lua MiniTrailspace.trim()` is available for manual cleanup.
*   **mini.statusline**: Provides a lightweight, informative statusline (with `LINE:COLUMN` location).
*   **mini.clue**: Shows helpful keybinding hints for common prefixes like `<leader>`, `g`, `z`, etc.
*   **mini.git**: Lightweight git integration (signs and commands) complementing `gitsigns.nvim`.
*   **hardtime.nvim**: Encourages you to use more efficient movement keys.
*   **smear-cursor.nvim**: Adds a smooth, "smearing" animation to your cursor movement.
*   **nvim-treesitter-context**: Shows the current code context (e.g., function/class) at the top of the window. Defaults to one line per scope level; use `<leader>c` to toggle full multiline context.
*   **nvim-colorizer.lua**: Highlights color codes (like hex / rgb) with their actual colors in the buffer.
