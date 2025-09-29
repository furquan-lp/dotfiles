# Syed's Dotfiles

A lot of stuff is WIP.

## My Neovim Cheatsheet

**Leader Key:** `,`

---

### **General & Editor**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<Esc>` | Normal | Clears search highlighting. |
| `<C-h>` | Normal | Move focus to the left window. |
| `<C-l>` | Normal | Move focus to the right window. |
| `<C-j>` | Normal | Move focus to the lower window. |
| `<C-k>` | Normal | Move focus to the upper window. |

---

### **Buffers & Files**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<S-TAB>` | Normal | Go to the previous buffer. |
| `<TAB>` | Normal | Go to the next buffer. |
| `<leader>E` | Normal | Toggle the `mini.files` file explorer. |
| `<leader><leader>` | Normal | [Telescope] Find existing buffers. |
| `<leader>sf` | Normal | [Telescope] Search files. |
| `<leader>s.` | Normal | [Telescope] Search recent files. |
| `<leader>sn` | Normal | [Telescope] Search Neovim config files. |

---

### **Search (Telescope)**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<leader>sf` | Normal | **S**earch **F**iles (respects .gitignore). |
| `<leader>sg` | Normal | **S**earch by **G**rep (live grep) in your project. |
| `<leader>sw` | Normal | **S**earch for the current **W**ord under the cursor. |
| `<leader>s/` | Normal | **S**earch by Grep in currently open files. |
| `<leader>/` | Normal | Fuzzily search within the current buffer. |
| `<leader>sh` | Normal | **S**earch **H**elp tags. |
| `<leader>sk` | Normal | **S**earch **K**eymaps. |
| `<leader>sd` | Normal | **S**earch **D**iagnostics (LSP errors, warnings). |
| `<leader>ss` | Normal | **S**earch **S**elect a Telescope picker. |
| `<leader>sr` | Normal | **S**earch **R**esume last Telescope search. |
| `<leader><leader>` | Normal | Find existing buffers. |

---

### **Editing & Text Objects**

These actions come from `mini.nvim` and `nvim-treesitter`.

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| **Commenting** (`mini.comment`) |
| `gcc` | Normal | Toggles the comment state for the current line. |
| `gc` | Normal / Visual | Toggles comments for the motion or visual selection (e.g., `gcip` for inner paragraph). |
| **Surrounding** (`mini.surround`) |
| `sa<char>` | Normal / Visual | **A**dd **s**urrounding `<char>` (e.g., `saw"` adds quotes around a word). |
| `sd<char>` | Normal | **D**elete **s**urrounding `<char>` (e.g., `sd"` deletes surrounding quotes). |
| `sr<from><to>` | Normal | **R**eplace **s**urrounding `<from>` char with `<to>` char (e.g., `sr'"` replaces single quotes with double). |
| **Treesitter Incremental Selection** |
| `<CR>` | Normal | Initialize selection of the current node. |
| `grn` | Normal / Visual | Increment selection to the parent node. |

---

### **LSP (Language Server Protocol)**

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
| `<leader>th` | Normal | **T**oggle inlay **H**ints. |

---

### **Diagnostics**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `[d` | Normal | Go to the previous diagnostic message. |
| `]d` | Normal | Go to the next diagnostic message. |
| `<leader>e` | Normal | Show diagnostic **E**rror messages in a floating window. |
| `<leader>q` | Normal | Open diagnostic **Q**uickfix list. |
| `<leader>sd` | Normal | [Telescope] **S**earch **D**iagnostics. |

---

### **Autocompletion (`blink.cmp` with super-tab preset)**

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

### **Formatting (`conform.nvim`)**

| Keymap | Mode(s) | Description |
| --- | --- | --- |
| `<leader>f` | Normal / Visual | **F**ormat the buffer or selection. |

---

### **Git (`gitsigns.nvim`)**

Gitsigns doesn't have many default keymaps, but it provides powerful commands and hunks navigation.

| Command/Key | Mode(s) | Description |
| --- | --- | --- |
| `]c` | Normal | Go to the next hunk (change). |
| `[c` | Normal | Go to the previous hunk. |
| `:Gitsigns toggle_current_line_blame` | Command | Toggle the git blame annotation for the current line. |

---

### **Plugin-Provided Features (No Keymaps)**

*   **guess-indent.nvim**: Automatically detects and sets indentation settings per file.
*   **mini.indentscope**: Provides visual guides for indentation levels.
*   **mini.trailspace**: Automatically highlights and removes trailing whitespace.
*   **hardtime.nvim**: Encourages you to use more efficient movement keys.
*   **smear-cursor.nvim**: Adds a smooth, "smearing" animation to your cursor movement.-cursor.nvim**: Adds a smooth, "smearing" animation to your cursor movement.
