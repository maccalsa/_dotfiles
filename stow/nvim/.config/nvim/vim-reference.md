# Vim / Neovim Ultimate Reference

A concise reference extracted for muscle memory. Vim is **editing smarter**, not typing faster. Master ~40 commands and you have 80% of Vim power.

---

## 1. Core Grammar

Every command follows this structure:

```
[count] operator [text-object | motion]
```

Think of it as **verb + target**.

| Component | Role |
| --- | --- |
| **Operator** | The action (delete, change, yank) |
| **Motion** | Where to apply (word, line, character) |
| **Text object** | Logical structure (inside quotes, inside brackets) |

**Example:** `ciw` = **c**hange + **i**nner **w**ord → replace the current word.

---

## 2. Quick Reference Tables

### Operators (Actions)

| Key | Meaning |
| --- | --- |
| d | delete |
| c | change (delete then insert) |
| y | yank (copy) |
| v | visual select |
| > | indent |
| < | outdent |
| = | auto format |

### Motions

| Key | Meaning |
| --- | --- |
| h j k l | left / down / up / right |
| w | next word |
| b | previous word |
| e | end of word |
| 0 | start of line |
| $ | end of line |
| gg | start of file |
| G | end of file |
| f\<char\> | find character |
| t\<char\> | until character |

### Text Objects

| Key | Meaning |
| --- | --- |
| iw | inner word |
| aw | around word |
| i" | inside quotes |
| a" | around quotes |
| i( | inside parentheses |
| i{ | inside braces |
| ip | inner paragraph |

---

## 3. Essential Commands

### Movement

```
h j k l      move left/down/up/right
w            next word
b            previous word
e            end of word
0            start of line
$            end of line
gg           top of file
G            bottom of file
f<char>      jump to character
t<char>      jump before character
;            repeat find forward
,            repeat find backward
```

### Editing

```
x            delete character
dd           delete line
yy           copy line (yank)
p            paste
u            undo
Ctrl+r       redo
.            repeat last command (very powerful)
dw           delete word
cw           change word
ciw          change inner word
```

### Text Objects

```
ci"          change inside quotes
ci(          change inside ()
ci{          change inside {}
di"          delete inside quotes
di(          delete inside ()
ya{          copy entire block including braces
```

### Find / Search

```
/pattern     search forward
?pattern     search backward
n            next result
N            previous result
*            search current word forward
#            search current word backward
```

---

## 4. Buffers & Files

A **buffer** is a file loaded into memory. Closing a window does not remove the buffer.

| Command | Action |
| --- | --- |
| `:ls` / `:buffers` | list buffers |
| `:b2` / `:buffer 2` | switch to buffer 2 |
| `:bn` | next buffer |
| `:bp` | previous buffer |
| `:bd` | delete buffer |
| `:e filename` | open file |
| `gf` | open file under cursor (imports) |
| `Ctrl+^` | switch between last two buffers (very useful) |

---

## 5. Splits & Windows

| Command | Action |
| --- | --- |
| `:vsp file` / `:vsplit file` | vertical split |
| `:sp file` / `:split file` | horizontal split |
| `Ctrl+w h` | move left |
| `Ctrl+w j` | move down |
| `Ctrl+w k` | move up |
| `Ctrl+w l` | move right |
| `:q` | close split |

---

## 6. Search & Replace

### In Current File

```
:%s/old/new/g      replace all
:%s/old/new/gc     replace with confirmation (y/n each)
```

Meaning: `%` = entire file, `s` = substitute, `g` = global.

### Replace Word Under Cursor

```
:%s/<C-r><C-w>/new/g
```

### Across Project

```
:grep foo **/*     search
:copen             open quickfix results
:cnext             next result
:cprev             previous result
:cdo s/foo/bar/g   replace in all results
```

---

## 7. Registers & Clipboard

Vim has **registers** (multiple clipboards). Yank and delete share the default register `"`.

### Black Hole (Delete Without Overwriting Clipboard)

```
"_dd
```

Use when you want to delete but keep what you yanked.

### Named Registers (a–z)

```
"ayy             copy line to register a
"ap              paste from register a
"ayiw            copy word to register a
```

### Visual Copy (Highlight + Copy)

```
v                character-wise visual
V                line-wise visual
Ctrl+v           block visual (columns)
```

Then move and press `y` to yank selection.

### System Clipboard

```
"+y              copy to system clipboard
"+p              paste from system clipboard
"+yy             copy line to system clipboard
```

### Paste Without Replacing Clipboard

```
"_dP             delete selection, paste; clipboard unchanged
```

---

## 8. Macros, Marks & Power Moves

### Marks

```
ma               set mark at cursor
'a               jump to mark a
```

### Macros

```
qa               start recording to register a
q                stop recording
@a               replay macro
10@a             replay 10 times
```

### Navigation

```
%                jump to matching bracket () {} []
Ctrl+o           jump back (like browser back)
Ctrl+i           jump forward (like browser forward)
Ctrl+d           scroll down half page
Ctrl+u           scroll up half page
```

---

## 9. The 7 Commands Developers Use Constantly

```
ciw              change inner word
ci"              change inside quotes
f                find character
.                repeat last command
%                jump to matching bracket
/search          search
Ctrl+^           switch last two buffers
```

---

## 10. Power Tricks

### Replace Word Everywhere

```
ciwnewName       change word
n                next match
.                repeat change
```

### Delete Until Character

```
dt,              delete until comma
```

### Block Edit Multiple Lines

```
Ctrl+v           block visual
select column
I                insert at start
type text
Esc              applies to all lines
```

### Search Current Word

```
*                search forward
#                search backward
```

---

## 11. Muscle Memory Drill

Replace variable names in:

```
const userName
const userAge
const userCity
```

```
ciwname
j
.
j
.
```

---

## 12. Learning Aids

### One Command Per Day

Pick one command, use it 100+ times that day.

### Forbidden Keys (Disable Arrows)

```lua
vim.keymap.set('', '<Up>', '<NOP>')
vim.keymap.set('', '<Down>', '<NOP>')
vim.keymap.set('', '<Left>', '<NOP>')
vim.keymap.set('', '<Right>', '<NOP>')
```

### Command Ladder

- **Level 1:** h j k l, w b e, 0 $, gg G
- **Level 2:** x, dw, cw, ciw, dd, yy, p
- **Level 3:** ., f, t, %, ci(, ci", ci{
- **Level 4:** /, *, n, N
- **Level 5:** macros, registers, marks, text objects

### Notebook Trick

Read a tiny cheat sheet once every morning.

### Tools

- **VimBeGood:** `:VimBeGood` (runs in nvim)
- **Vim Adventures:** https://vim-adventures.com
- **VimGolf:** https://www.vimgolf.com
- **asciinema:** record sessions, watch yourself to spot inefficiencies

### 30-Day Plan (10 min/day)

| Week | Focus |
| --- | --- |
| 1 | Movement (hjkl, w b e, 0 $, gg G, f t ;) |
| 2 | Editing (x, dd, yy, p, dw, cw, ciw, .) |
| 3 | Text objects (ci", ci(, ci{, di", viw) |
| 4 | Power tools (/, %s, splits, buffers, marks, macros, registers) |

---

## Final Tip

Don't memorize commands. Learn **patterns**: `operator + object`. Once you know `di"`, `ci"`, `yi"`, you know dozens of commands.
