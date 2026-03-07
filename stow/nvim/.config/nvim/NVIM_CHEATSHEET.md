# Neovim Issue Mode Cheat Sheet

Leader key: **Space**

## Startup

- **`nvim`** – Opens the dashboard (you're in your shell's current directory; use `:pwd` to check)
- **`nvim .`** – Also opens the dashboard (replaces netrw)
- **`Space a d`** – Open Alpha dashboard from anywhere

## File / Search

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
