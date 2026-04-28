# Syed's Dotfiles

A lot of stuff is WIP.

## My Neovim Cheatsheet

**Leader Key:** `,`

### Profiles

The default `nvim` command loads the full editing profile with plugins, LSP, Telescope, completion, formatting, git signs, UI helpers, and per-project sessions.

Use the minimal profile when you want a calmer editor with the shared core settings but without plugin-backed features, Lazy startup, or per-project session save/restore:

```sh
NVIM_MINIMAL=1 nvim
nvim-min
svim /etc/some-file
```

`svim` uses `sudoedit` with `$HOME/.local/bin/nvim`, so Neovim runs as your user while `sudoedit` writes the file back with elevated permissions.

Git is configured to use the same minimal profile for commit messages:

```ini
[core]
	editor = env NVIM_MINIMAL=1 nvim
```

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
| `<leader><TAB>` | Normal | Full profile: go to the next buffer and show the buffer list on one line. |
| `<S-TAB>` | Normal | Full profile: go to the previous buffer and show the buffer list on one line. |
| `<leader>bd` | Normal | Close all other buffers, keeping only the current one. |
| `<leader>E` | Normal | Full profile: toggle the `mini.files` file explorer. |
| `<leader>yp` | Normal | Copy the current file's **relative path** to the system clipboard. |

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
| `<leader><leader>` | Normal | Find existing buffers. |

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
| `<leader>q` | Normal | Open diagnostic **Q**uickfix list. |
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

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<leader>f` | Normal / Visual | **F**ormat the buffer or selection. |

---

### **Git (`gitsigns.nvim`, Full Profile)**

Gitsigns doesn't have many default keymaps, but it provides powerful commands and hunks navigation.

| Command/Key | Mode(s) | Description |
| --- | --- | --- |
| `]c` | Normal | Go to the next hunk (change). |
| `[c` | Normal | Go to the previous hunk. |
| `<leader>gb` | Normal | Show a detailed git blame popup for the current line. |
| `<leader>gd` | Normal | Preview the current git hunk in a floating window. |
| `:Gitsigns toggle_current_line_blame` | Command | Toggle the git blame annotation for the current line. |

---

### **Plugin-Provided Features (No Keymaps, Full Profile)**

*   **guess-indent.nvim**: Automatically detects and sets indentation settings per file.
*   **mini.indentscope**: Provides visual guides for indentation levels.
*   **mini.trailspace**: Automatically highlights and removes trailing whitespace.
*   **mini.statusline**: Provides a lightweight, informative statusline (with `LINE:COLUMN` location).
*   **mini.clue**: Shows helpful keybinding hints for common prefixes like `<leader>`, `g`, `z`, etc.
*   **mini.git**: Lightweight git integration (signs and commands) complementing `gitsigns.nvim`.
*   **hardtime.nvim**: Encourages you to use more efficient movement keys.
*   **smear-cursor.nvim**: Adds a smooth, "smearing" animation to your cursor movement.
*   **nvim-treesitter-context**: Shows the current code context (e.g., function/class) at the top of the window. Defaults to one line per scope level; use `<leader>c` to toggle full multiline context.
*   **nvim-colorizer.lua**: Highlights color codes (like hex / rgb) with their actual colors in the buffer.
