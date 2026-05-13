# Neovim Issue Mode Cheat Sheet

Leader key: **Space**

## Startup

- **`nvim`** – Opens the dashboard (you're in your shell's current directory; use `:pwd` to check)
- **`nvim .`** – Also opens the dashboard (replaces netrw)
- **`Space a d`** – Open Alpha dashboard from anywhere

## Telescope Search

| Keys | Action |
|------|--------|
| `Space s f` | Search files |
| `Space s g` | Search by grep |
| `Space s h` | Search help |
| `Space s k` | Search keymaps |
| `Space s s` | Select Telescope picker |
| `Space s w` | Search current word |
| `Space s d` | Search diagnostics |
| `Space s r` | Resume last search |
| `Space s .` | Recent files |
| `Space s /` | Search open files |
| `Space s n` | Search Neovim config files |
| `Space Space` | Find existing buffers |

## File Shortcuts

| Keys | Action |
|------|--------|
| `Space f f` | Find files |
| `Space f g` | Live grep repo |
| `Space f b` | Buffers |
| `Space f r` | Recent files |

## Git / Issue Mode

| Keys | Action |
|------|--------|
| `Space g m` | Modified tracked files |
| `Space g M` | Grep modified tracked files |
| `Space g s` | Git status |
| `Space g b` | Git branches |

## Harpoon (Jump)

| Keys | Action |
|------|--------|
| `Space j a` | Add current file |
| `Space j h` | Harpoon menu |
| `Space j 1`–`4` | Jump to slot 1–4 |
| `Space j n` | Next Harpoon file |
| `Space j p` | Previous Harpoon file |

## Built-in

| Keys | Action |
|------|--------|
| `Ctrl-^` | Jump between last two files |

## Windows / Splits

| Keys | Action |
|------|--------|
| `Ctrl-h` | Move focus left |
| `Ctrl-j` | Move focus down |
| `Ctrl-k` | Move focus up |
| `Ctrl-l` | Move focus right |
| `Space w v` | Split window vertically |
| `Space w -` | Split window horizontally |
| `Space w e` | Make splits equal size |
| `Space w x` | Close current split |

## Editing (mini.surround)

| Keys | Action |
|------|--------|
| `saiw"` | Surround word with quotes |
| `saiw)` | Surround word with parens |
| `V` then `sa"` | Surround line (visual line + add) |
| `sr"'` | Replace `"` with `'` |
| `sd"` | Delete surrounding quotes |
| `sf` / `sF` | Find right/left surrounding |
| `sh` | Highlight surrounding |

## Essential Vim

| Keys | Action |
|------|--------|
| `ciw` | Change word |
| `ci"` | Change inside quotes |
| `.` | Repeat last edit |
| `"_dd` | Delete without overwriting yank |
| `"+yy` | Copy line to system clipboard |

## Format

| Keys | Action |
|------|--------|
| `Space c f` | Format buffer |
