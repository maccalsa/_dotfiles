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

## Code Navigation / LSP

These work in any language with an attached language server.

| Keys | Action |
|------|--------|
| `g d` | Go to definition |
| `g r` | Find references |
| `g I` | Go to implementation |
| `g D` | Go to declaration |
| `K` | Hover documentation |
| `Space D` | Type definition |
| `Space d s` | Document symbols |
| `Space w s` | Workspace symbols |
| `Space r n` | Rename symbol |
| `Space c a` | Code actions |
| `[` `d` | Previous diagnostic |
| `]` `d` | Next diagnostic |
| `Space e` | Show diagnostic details |
| `Space q` | Open diagnostic quickfix |

## Completion

| Keys | Action |
|------|--------|
| `Ctrl-Space` | Trigger autocomplete |
| `Tab` / `Shift-Tab` | Select next / previous completion |
| `Enter` | Accept selected completion |
| `Ctrl-b` / `Ctrl-f` | Scroll completion docs |
| `Ctrl-l` / `Ctrl-h` | Jump forward / backward in snippets |

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

If Kotlin formatting times out on save, it is usually `ktlint` taking longer than the formatter timeout, not necessarily a broken project. Kotlin and Java get a longer save-format timeout than small files because their formatters often need more startup time.

## Errors / Logs

| Keys / Command | Action |
|------|--------|
| `Space e` | Show diagnostic details under cursor |
| `Space q` | Open diagnostics quickfix |
| `Space s d` | Search diagnostics with Telescope |
| `:LspInfo` | Show attached language servers |
| `:ConformInfo` | Show formatter status |
| `:checkhealth vim.lsp` | Check LSP health |
| `less ~/.local/state/nvim/lsp.log` | Inspect LSP startup/runtime errors |

## Kotlin LSP Install

This config uses JetBrains' official Kotlin LSP, which requires JDK 25. Install it on another machine with:

```sh
mkdir -p "$HOME/.local/share/kotlin-lsp/262.4739.0"
curl -L "https://download-cdn.jetbrains.com/kotlin-lsp/262.4739.0/kotlin-server-262.4739.0.tar.gz" \
  | tar -xz -C "$HOME/.local/share/kotlin-lsp/262.4739.0" --strip-components=1
```

The configured binary path is:

```sh
$HOME/.local/share/kotlin-lsp/262.4739.0/bin/intellij-server
```

## Java / Spring / Gradle

Full Java/Spring support uses `nvim-java`, which requires Neovim 0.11.5+.

| Keys | Action |
|------|--------|
| `Space J b` | Build Java workspace |
| `Space J B` | Clean Java workspace |
| `Space J r` | Run main class / Spring Boot app |
| `Space J R` | Stop running Java app |
| `Space J l` | Toggle Java app logs |
| `Space J p` | Open Java profiles UI |
| `Space J d` | Configure Java debugger |
| `Space J t` | Run test method |
| `Space J T` | Run test class |
| `Space J a` | Run all tests |
| `Space J v` | View last test report |
| `Space J C` | Change Java runtime |
| `Space J r e` | Extract variable |
| `Space J r c` | Extract constant |
| `Space J r m` | Extract method |

## Avante AI

Set `OPENROUTER_API_KEY` in your shell. Optionally set `OPENROUTER_MODEL`.

| Keys | Action |
|------|--------|
| `Space a a` | Ask Avante |
| `Space a c` | Open Avante chat |
| `Space a n` | New Avante chat |
| `Space a e` | Edit with Avante |
| `Space a f` | Focus Avante panel |
| `Space a t` | Toggle Avante panel |
| `Space a s` | Stop Avante request |
| `Space a m` | List Avante models |
| `Space a p` | Switch Avante provider |
| `Space a r` | Show Avante repo map |

## HTTP Requests

Uses IntelliJ-compatible `.http` / `.rest` files and `.env.json` environments.

| Keys | Action |
|------|--------|
| `Space R f` | Select HTTP environment file |
| `Space R e` | Select HTTP environment |
| `Space R r` | Run request under cursor |
| `Space R a` | Run all requests in file |
| `Space R x` | Stop request |
| `Space R v` | Toggle verbose mode |
| `Space R p` | Toggle profiling |
| `Space R d` | Dry run request |
| `Space R c` | Copy request as curl |
| `Space R s` | Save response |
| `Space R g` | Set HTTP project root |
| `Space R G` | Show HTTP project root |

## Database

Uses DBee. Define connections with `DBEE_CONNECTIONS` or add them through DBee's data-file source.

| Keys | Action |
|------|--------|
| `Space d b` | Toggle DBee |
| `Space d o` | Open DBee |
| `Space d c` | Close DBee |
