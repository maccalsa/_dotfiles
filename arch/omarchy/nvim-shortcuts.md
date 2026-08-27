# Neovim shortcuts (Omarchy LazyVim)

Leader is **Space**. This is the Omarchy LazyVim setup plus the `arch/stow` overlay (language extras, HTTP client, DBee). It is not the Ubuntu kickstart nvim.

If you forget a key, `Space sk` searches keymaps. `Space ?` shows buffer-local maps.

Omarchy sets `vim.g.autoformat = false`, so files do **not** format on save until you format yourself.

---

## The move-a-function workflow

Neovim will not rewrite every call site the way IntelliJ's Move refactor does. Closest IDE path:

1. **Go to the source file:** `Space Space` or `Space ff` (find files). Type a path fragment, `Enter`.
2. **Land on the function:** `Space ss` (symbols in this file). Or jump with `]f` / `[f`.
3. **Grab the whole function:** `vaf` (visual around function) then `y` to yank, or `yaf` in one shot. `daf` cuts it.
4. **Open the destination:** `Space Space` again, or `Space e` for Neo-tree.
5. **Paste:** `p` or `P`. Then `Space ca` and pick **Add import** if the compiler/LSP complains. `Space co` organizes imports when the language server supports it.

Rename the leftover identifier with `Space cr` (LSP rename) so other files update. That is the refactor you *do* have. There is no `F6` Move.

`Ctrl-Space` also grows a treesitter selection (Flash), like IntelliJ `Ctrl+W`. Inside tmux, Omarchy's prefix is `Ctrl-Space`, so send it with `Ctrl-Space Ctrl-Space`.

---

## Jump around a project

| Keys | Action |
| --- | --- |
| `Space Space` | Find files (root) |
| `Space ff` | Same as above |
| `Space fF` | Find files (cwd) |
| `Space /` or `Space sg` | Grep project |
| `Space fr` | Recent files |
| `Space fb` or `Space ,` | Open buffers |
| `Space ss` | Symbols in this file (functions, methods, fields) |
| `Space sS` | Workspace symbols |
| `Space e` | Neo-tree (root) |
| `]f` / `[f` | Next / previous function |
| `]c` / `[c` | Next / previous class |
| `s` | Flash jump (label, then type) |
| `S` | Flash treesitter jump |
| `Ctrl-O` / `Ctrl-I` | Jump back / forward |

---

## Definition, docs, references

| Keys | Action |
| --- | --- |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `gr` | References (picker) |
| `K` | Hover docs (the native "explain this") |
| `gK` / `Ctrl-K` (insert) | Signature help |
| `Space cS` | LSP references/defs in Trouble |
| `gai` / `gao` | Incoming / outgoing calls |

Hover is the closest thing to IntelliJ `Ctrl+Q`. There is no built-in AI "explain code" in this overlay (Avante was not ported).

---

## Errors and inspections

Squiggles are automatic from the LSP.

| Keys | Action |
| --- | --- |
| `]d` / `[d` | Next / previous diagnostic |
| `]e` / `[e` | Next / previous error |
| `Space cd` | Line diagnostic float |
| `Space xx` | Project diagnostics (Trouble) |
| `Space xX` | Buffer diagnostics (Trouble) |
| `Space sd` | Diagnostics picker |
| `Space ca` | Code action (fix, import, extract if the server offers it) |

`Space cl` shows which language servers are attached.

---

## Format and imports

Format exists. Auto-import is LSP-driven, not IntelliJ-style "on the fly."

| Keys | Action |
| --- | --- |
| `Space cf` | Format buffer (or visual selection) |
| `Space ca` | Code action: **Add import**, fix, extract, … |
| `Space co` | Organize imports (when the server supports `source.organizeImports`) |
| `Space uf` | Toggle format-on-save for this session |

Go, Rust, Java, TypeScript, JSON, YAML, Docker, Kotlin, Markdown extras are enabled. Formatters come from those extras + Mason. If `Space cf` does nothing, `:Mason` and `:checkhealth` — the server or formatter is missing.

To make save format like IntelliJ Actions on Save, set `vim.g.autoformat = true` in `~/.config/nvim/lua/config/options.lua` (Omarchy currently forces it off).

---

## Select and edit like an IDE

mini.ai text objects (operator + `a`/`i` + object):

| Object | Meaning | Example |
| --- | --- | --- |
| `f` | Function | `yaf` yank function, `vaf` select, `daf` cut |
| `c` | Class | `vac` |
| `o` | Block / if / loop | `vao` |
| `a` | Argument | `cia` change argument |
| `g` | Whole buffer | `yag` |

Treesitter moves: `]f` `[f` `]c` `[c`.

| Keys | Action |
| --- | --- |
| `Space cr` | Rename symbol (project-wide via LSP) |
| `Space cR` | Rename file (LSP-aware) |
| `gcc` / `gc` (visual) | Toggle comment |
| `Space \|` / `Space -` | Split window right / below |
| `Space wd` | Close window |
| `Ctrl-H/J/K/L` | Move between windows |
| `Alt-j` / `Alt-k` | Move line down / up |

---

## Overlay extras (not LazyVim stock)

HTTP (`.http` files):

| Keys | Action |
| --- | --- |
| `Space Rr` | Run request |
| `Space Ra` | Run all |
| `Space Re` | Set env |
| `Space Rf` | Select env file |
| `Space Rc` | Copy as curl |
| `Space Rx` | Stop |

Database:

| Keys | Action |
| --- | --- |
| `Space Dt` | Toggle DBee |
| `Space Do` / `Space Dc` | Open / close |

Markdown preview (from `lang.markdown`): `Space cp`.

---

## Honest gaps vs IntelliJ

| IntelliJ | Neovim here |
| --- | --- |
| Move refactor (`F6`) updates all call sites | Yank/delete function + paste; rename with `Space cr` |
| Auto-import on the fly | `Space ca` → Add import; `Space co` organize |
| Reformat on save (optional) | Off by default; `Space cf` or toggle `Space uf` |
| Extract method / variable as first-class | Only if the LSP code action lists them (`Space ca`) |
| Quick definition peek | `gd` jumps; no peek popup |
| Find Action (`Ctrl+Shift+A`) | `Space sk` (keymaps) or `Space sC` (commands) |
| Problems tool window | `Space xx` Trouble |

Language servers must actually attach. Open a real project file and run `:LspInfo` (or `Space cl`). Java wants the Gradle/Maven root; Kotlin uses official `kotlin_lsp`; Odin uses `ols`.
