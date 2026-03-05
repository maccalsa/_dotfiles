# Neovim KeyCoach – MVP Plugin Scaffold

A minimal, working Neovim plugin that watches normal‑mode keystrokes, detects simple “inefficient” edits, and shows a gentle floating hint suggesting a better motion/operator.

---

## Project structure

```
keycoach/
├─ plugin/
│  └─ keycoach.lua
├─ lua/
│  └─ keycoach/
│     ├─ init.lua
│     ├─ rules.lua
│     └─ ui.lua
└─ README.md
```

---

## plugin/keycoach.lua

```lua
-- Loaded automatically by Neovim when the plugin is on 'runtimepath'
if vim.g.loaded_keycoach then return end
vim.g.loaded_keycoach = true

vim.api.nvim_create_user_command('KeyCoachToggle', function()
  require('keycoach').toggle()
end, { desc = 'Toggle KeyCoach on/off' })

vim.api.nvim_create_user_command('KeyCoachStats', function()
  require('keycoach').stats()
end, { desc = 'Show KeyCoach counters' })

-- Auto-enable on startup (you can change this default)
vim.schedule(function()
  require('keycoach').enable()
end)
```

---

## lua/keycoach/init.lua

```lua
local M = {}

local ns = vim.api.nvim_create_namespace('keycoach')
local enabled = false

local state = {
  keys = {},
  last_tick = 0,
  timer = nil,
  counters = {
    rule_x_spam = 0,
    rule_hl_walk = 0,
  },
}

local function in_coachable_context()
  local m = vim.api.nvim_get_mode().mode
  if not m:match('^[nv]') then return false end
  -- avoid terminals, prompts, help, quickfix, etc.
  local bt = vim.bo.buftype
  if bt ~= '' and bt ~= 'acwrite' then return false end
  if vim.tbl_contains({ 'help', 'terminal', 'nofile', 'prompt', 'quickfix' }, bt) then return false end
  if vim.fn.reg_recording() ~= '' then return false end -- macros
  if vim.fn.mode() ~= 'n' then return false end -- only normal mode
  return true
end

local function reset_keys()
  state.keys = {}
end

local function snapshot_after()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local from_line = math.max(0, row - 6)
  local to_line = row + 5
  local lines = vim.api.nvim_buf_get_lines(bufnr, from_line, to_line, false)
  return { row = row, from = from_line, to = to_line, lines = lines }
end

local function on_pause_after_change()
  local after = snapshot_after()
  local suggestion = require('keycoach.rules').suggest(state.keys, after)
  reset_keys()
  if suggestion then
    if suggestion.key == 'rule_x_spam' then state.counters.rule_x_spam = state.counters.rule_x_spam + 1 end
    if suggestion.key == 'rule_hl_walk' then state.counters.rule_hl_walk = state.counters.rule_hl_walk + 1 end
    require('keycoach.ui').hint(suggestion.text, suggestion.example)
  end
end

local function ensure_timer()
  if state.timer then return end
  state.timer = vim.loop.new_timer()
end

local function arm_debounce(ms)
  ensure_timer()
  state.timer:stop()
  state.timer:start(ms, 0, vim.schedule_wrap(on_pause_after_change))
end

local function on_key(key)
  if not enabled then return end
  if not in_coachable_context() then return end
  table.insert(state.keys, { key = key, t = vim.loop.now() })
end

local function on_text_changed()
  if not enabled then return end
  local tick = vim.b.changedtick or 0
  if tick == state.last_tick then return end
  state.last_tick = tick
  -- Wait a short moment for the user to pause before analyzing
  arm_debounce(350)
end

function M.enable()
  if enabled then return end
  enabled = true
  reset_keys()
  vim.on_key(on_key, ns)
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = vim.api.nvim_create_augroup('KeyCoachChanged', { clear = true }),
    callback = on_text_changed,
  })
end

function M.disable()
  if not enabled then return end
  enabled = false
  reset_keys()
  if state.timer then state.timer:stop() end
  vim.on_key(nil, ns)
  pcall(vim.api.nvim_del_augroup_by_name, 'KeyCoachChanged')
end

function M.toggle()
  if enabled then M.disable() else M.enable() end
end

function M.stats()
  local lines = {
    'KeyCoach stats:',
    ('  x/dl spam → dw/daw: %d'):format(state.counters.rule_x_spam),
    ('  h/l walking → f/t/w/b: %d'):format(state.counters.rule_hl_walk),
  }
  require('keycoach.ui').hint(table.concat(lines, '\n'))
end

return M
```

---

## lua/keycoach/rules.lua

```lua
local R = {}

-- Simple utility to count a tail run of keys matching a predicate
local function tail_run(keys, pred)
  local n = 0
  for i = #keys, 1, -1 do
    if pred(keys[i].key) then n = n + 1 else break end
  end
  return n
end

-- Rule 1: repeated deletions with x/dl in the same burst → suggest dw/daw
local function rule_x_spam(keys, after)
  local n = tail_run(keys, function(k) return k == 'x' or k == 'dl' or k == '\127' end) -- '\127' = BS sometimes
  if n >= 3 then
    return { key = 'rule_x_spam', score = 10, text = 'Tip: use operator + motion', example = 'Example: `dw` deletes to next word, `daw` deletes a word incl. space' }
  end
end

-- Rule 2: excessive h/l (or left/right) walking → suggest f/t/w/b
local function rule_hl_walk(keys, after)
  local n = tail_run(keys, function(k) return k == 'h' or k == 'l' or k == '\u{001b}[D' or k == '\u{001b}[C' end)
  if n >= 6 then
    return { key = 'rule_hl_walk', score = 8, text = 'Tip: jump instead of walking', example = 'Try `f{char}` / `t{char}` or `w`/`b` to move faster' }
  end
end

-- Choose the highest score suggestion (expandable)
local RULES = { rule_x_spam, rule_hl_walk }

function R.suggest(keys, after)
  local best
  for _, rule in ipairs(RULES) do
    local sug = rule(keys, after)
    if sug and ((not best) or (sug.score > best.score)) then best = sug end
  end
  return best
end

return R
```

---

## lua/keycoach/ui.lua

```lua
local U = {}

local function place_top_right(buf, width, height)
  local win = vim.api.nvim_get_current_win()
  local cols = vim.api.nvim_win_get_width(win)
  local row = 1
  local col = math.max(1, cols - width - 2)
  return {
    relative = 'win',
    win = win,
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    noautocmd = true,
  }
end

local function truncate_lines(lines, maxw)
  local out = {}
  for _, l in ipairs(lines) do
    if #l > maxw then l = l:sub(1, maxw - 1) .. '…' end
    table.insert(out, l)
  end
  return out
end

function U.hint(text, subtitle)
  if type(text) ~= 'string' then return end
  local lines = { 'KeyCoach', text }
  if subtitle and subtitle ~= '' then table.insert(lines, subtitle) end

  lines = truncate_lines(lines, 68)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  local width = 2
  for _, l in ipairs(lines) do width = math.max(width, #l + 2) end
  local height = #lines

  local opts = place_top_right(buf, width, height)
  local win = vim.api.nvim_open_win(buf, false, opts)
  vim.api.nvim_set_option_value('winblend', 20, { win = win })

  -- auto-close after a short time
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, 1800)
end

return U
```

---

## README.md

````md
# KeyCoach (MVP)

A tiny Neovim coach that watches normal‑mode keystrokes and suggests a faster Vim-native command when it detects an inefficient pattern.

## Install (lazy.nvim)

```lua
{
  'yourname/keycoach',
  dir = '~/dev/keycoach', -- path to this folder while developing
  config = function()
    -- Auto‑enabled by default; commands below:
    -- :KeyCoachToggle  -- toggle on/off
    -- :KeyCoachStats   -- show basic counters
  end,
}
````

## Usage

* Just edit as usual. If you spam `x`/`dl` to delete or walk with `h`/`l` a lot, a subtle popup will suggest `dw`/`daw` or `f`/`t`/`w`.
* `:KeyCoachToggle` to disable temporarily.

## Roadmap

* More rules (text‑objects, `.` repeat, join lines, case changes, indent objects).
* Per‑filetype enable/disable.
* Tree‑sitter contextual rules.
* Optional native (Rust) diff helper via `nvim‑oxi` if needed.

```
```
