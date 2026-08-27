# IntelliJ IDEA shortcuts (Linux)

Default IntelliJ keymap. Leader-style muscle memory from Neovim does not apply here: these are IDE actions.

If a chord does nothing, Hyprland or tmux likely stole it. Open **Find Action** (`Ctrl+Shift+A`) and type the command name instead.

Install with `./arch/omarchy/install-intellij.sh`.

---

## The move-a-function workflow

Do **not** treat this as a text editor copy. IntelliJ can move the symbol and fix imports/call sites.

1. **Go to the source file:** `Ctrl+Shift+N` (Go to File). Type a path fragment, `Enter`.
2. **Land on the function:** `Ctrl+F12` (File Structure), type the name, `Enter`.
3. **Move it (preferred):** with the caret inside the function, `F6` (Move). Pick the target class/file. IntelliJ updates references.
4. **Or copy-paste:**
   - `Ctrl+W` repeatedly until the whole function is selected (`Ctrl+Shift+W` shrinks).
   - `Ctrl+C`.
   - `Ctrl+Shift+N` to the destination file.
   - Put the caret where it belongs, `Ctrl+V`.
   - `Ctrl+Alt+O` to fix imports, `Alt+Enter` on any remaining red.

Related: `F5` copies a class/file. `Shift+F6` renames a symbol everywhere.

---

## Jump around a project

| Keys | Action |
| --- | --- |
| `Shift Shift` | Search Everywhere (files, classes, symbols, actions) |
| `Ctrl+Shift+N` | Go to file |
| `Ctrl+N` | Go to class |
| `Ctrl+Alt+Shift+N` | Go to symbol (function, method, field, constant) |
| `Ctrl+E` | Recent files |
| `Ctrl+Shift+E` | Recent locations |
| `Ctrl+F12` | File structure: methods / functions / fields in this file |
| `Ctrl+G` | Go to line |
| `Ctrl+B` / `Ctrl+Click` | Go to declaration (definition) |
| `Ctrl+Alt+B` | Go to implementation |
| `Ctrl+U` | Go to super method |
| `Ctrl+Shift+B` | Go to type declaration |
| `Ctrl+Alt+Left` / `Right` | Navigate back / forward (often stolen on Linux) |

---

## Definition, docs, references

| Keys | Action |
| --- | --- |
| `Ctrl+B` | Go to definition |
| `Ctrl+Shift+I` | Peek definition (quick definition popup) |
| `Ctrl+Q` | Quick documentation (the native "explain this") |
| `Ctrl+P` | Parameter info |
| `Ctrl+Shift+P` | Expression type |
| `Alt+F7` | Find usages (go to references across the project) |
| `Ctrl+Alt+F7` | Show usages in a popup |

Hover plus `Ctrl` also peeks the destination. If you have JetBrains AI, select code → right click → **AI Actions → Explain Code**; `Ctrl+Q` is still the one that always works.

---

## Errors and inspections

Red/yellow squiggles are automatic. You do not need a highlight toggle.

| Keys | Action |
| --- | --- |
| `F2` / `Shift+F2` | Next / previous highlighted error |
| `Ctrl+F1` | Error / warning description at caret |
| `Alt+Enter` | Context actions: fix, import, suppress, generate |
| `Alt+6` | Problems tool window |
| `Ctrl+Alt+Shift+I` | Run inspection by name |

The inspection widget in the top-right of the editor is the same error list as `F2`.

---

## Format and imports

Yes: format and auto-import are first-class.

| Keys | Action |
| --- | --- |
| `Ctrl+Alt+L` | Reformat file (or selection) |
| `Ctrl+Alt+I` | Auto-indent selection |
| `Ctrl+Alt+O` | Optimize imports (remove unused, sort) |
| `Alt+Enter` | Add import for the unresolved symbol under the caret |

Turn on fly-imports so most of this is automatic:

1. **Settings → Editor → General → Auto Import**
2. Enable **Add unambiguous imports on the fly**
3. Enable **Optimize imports on the fly** (optional, a bit aggressive)

Optional: **Settings → Tools → Actions on Save** → Reformat code + Optimize imports.

---

## Edit like an IDE, not a buffer

| Keys | Action |
| --- | --- |
| `Ctrl+W` / `Ctrl+Shift+W` | Extend / shrink selection (word → expression → function) |
| `Ctrl+D` | Duplicate line or selection |
| `Ctrl+Y` | Delete line |
| `Ctrl+/` | Toggle line comment |
| `Ctrl+Shift+/` | Toggle block comment |
| `Ctrl+Shift+Up` / `Down` | Move statement up / down |
| `Ctrl+Alt+M` | Extract method |
| `Ctrl+Alt+V` | Extract variable |
| `Ctrl+Alt+C` | Extract constant |
| `Ctrl+Alt+T` | Surround with (if, try, function, …) |
| `Alt+Insert` | Generate (constructor, getters, override, test, …) |
| `Ctrl+Z` / `Ctrl+Shift+Z` | Undo / redo |
| `Ctrl+Shift+V` | Paste from clipboard history |

---

## Everyday search

| Keys | Action |
| --- | --- |
| `Ctrl+Shift+A` | Find action (when you forget a shortcut) |
| `Ctrl+F` / `Ctrl+R` | Find / replace in file |
| `Ctrl+Shift+F` / `Ctrl+Shift+R` | Find / replace in path |
| `Ctrl+Shift+F12` | Maximize editor (hide tool windows) |
| `Alt+1` | Project tool window |
| `Alt+F12` | Terminal |

---

## Settings worth enabling once

- **Auto Import** as above.
- **Actions on Save:** reformat + optimize imports for the languages you care about.
- **Editor → General → Code Completion:** if you want docs in the completion popup, enable documentation.
- **Keymap:** if `Ctrl+Alt+Left` is eaten by Hyprland, search keymap for **Back** and bind something else (for example `Alt+Shift+Left`).

`Double Shift` then typing `Reformat File`, `Move`, `Find Usages`, or `Optimize Imports` always works, even when the chord is rebound.
