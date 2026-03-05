Short answer: yes—great idea. Think “Key Promoter X for Neovim,” but smarter, because we can observe what changed in the buffer and suggest the *Vim-native* way to do it (motions, text-objects, operators) instead of just nagging.

Here’s how I’d approach it:

# What it would do

* **Watch keystrokes in normal mode** and **diff buffer changes** over short windows.
* **Classify the edit** (delete word, change inside parens, join lines, move block, etc.).
* **Suggest the idiomatic command** that would have achieved the same result faster/cleaner (e.g., you spammed `x x x` → suggest `dw` or `daw`; you navigated char-by-char → suggest `f`/`t` + motion; changed inside parentheses with many steps → suggest `ci(`).
* **Coach gently:** small floating hint with opt-in gamified streaks, snooze/mute per rule, never interrupt macros/insert mode.

# Why it’s feasible

* Neovim gives you the hooks you need:

  * `vim.on_key(cb, ns)` to capture keys (0.8+).
  * `vim.b.changedtick` + snapshots to know *when* a buffer changed.
  * `nvim_buf_get_lines()`/`nvim_buf_get_text()` to snapshot small regions.
  * Floating windows for subtle hints.
* A big chunk is **heuristics**, not heavy AI: lots of “if you did X in ≥N keystrokes, you probably wanted Y”.

# High-level architecture

* **Lua Frontend (plugin core)**

  * Capture keystrokes, debounce a “candidate edit” window (e.g., 300–600ms of inactivity).
  * Grab *before/after* slices around the cursor (smart radius, like ±5 lines).
  * Send to a classifier (in-proc Lua first).
  * Show a hint in a float; record telemetry locally (counts per rule) for progress.
* **Classifier (start simple)**

  1. **Rules/heuristics:** common patterns:

     * Repeated `x`/`dl` → `dw`, `daw`
     * Many `l`/`h`/arrow steps → `w`, `b`, `e`, `f{char}`, `t{char}`
     * Select/delete/change with manual moves → `ciw`, `ci(`, `di"`, `da'`, `dap`, `dip`, `vi}` then op, etc.
     * Manual join with deletes → `J`/`gJ`
     * Upper/lower casing per word → `gUw`/`guw`
     * Indent/unindent multi-lines → `>ip`, `<ip` or `=ip`
     * Move line(s) with cut/paste → `:m` or `]e`/`[e` style mappings if provided
     * Multiple repeats of the same change → teach `.` repeat
  2. **Contextual rules via Tree-sitter (phase 2):**

     * “change function args” → `ci(`
     * “around string” → `ci"`/`da'`
* **Optional fast diff engine**

  * Start with Lua/Neovim’s built-ins. If you need speed, call out to **Rust** with `nvim-oxi` (or Python) to run a Myers diff and return an edit script.

# MVP scope (2–3 evenings)

1. Record keys via `vim.on_key`, ignore Insert/Macro/Ex modes.
2. When `changedtick` bumps, snapshot small region before/after.
3. Run 10–12 deterministic rules; pick the best suggestion.
4. Show a tiny float for ~2 seconds, e.g. “Try `ciw` next time (press `?` to learn)”.
5. Add **Snooze/Disable** for the rule from the popup.
6. Persist local counters; add `:KeyCoach Stats`.

# Nice UX touches

* **Hint heat:** only show if user took “inefficient path” (keystrokes > threshold).
* **Learning mode:** temporary overlays mapping motions on demand (press a key to reveal top 3 alternatives).
* **Respect user choices:** whitelist/blacklist rules, per-filetype toggles.
* **No spam:** rate-limit hints; never show in quickfix, terminal, LSP rename, macros, etc.

# Skeleton (Lua)

```lua
-- init.lua (plugin entry)
local ns = vim.api.nvim_create_namespace("keycoach")
local state = { keys = {}, last_tick = 0, last_snapshot = nil, pending_timer = nil }

-- capture keys
vim.on_key(function(key)
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("^[nv]") then
    table.insert(state.keys, { key = key, time = vim.loop.now() })
  end
end, ns)

-- observe buffer changes
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  callback = function()
    local tick = vim.b.changedtick or 0
    if tick == state.last_tick then return end
    state.last_tick = tick
    if state.pending_timer then state.pending_timer:stop(); state.pending_timer:close() end

    -- debounce: wait for user to pause
    state.pending_timer = vim.loop.new_timer()
    state.pending_timer:start(400, 0, vim.schedule_wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local from_line = math.max(0, row - 6)
      local to_line   = row + 5
      local after = vim.api.nvim_buf_get_lines(bufnr, from_line, to_line, false)

      local suggestion = require("keycoach.rules").suggest(state.keys, after)
      state.keys = {} -- reset window

      if suggestion then
        require("keycoach.ui").hint(suggestion.text, suggestion.example)
      end
    end))
  end
})
```

You’d implement `keycoach.rules.suggest(keys, after)` with a few heuristics like:

* If we see ≥3 consecutive `x`/`dl` on the same line → suggest `dw`/`daw`.
* If cursor moved >5 columns via `h/l` without using a motion → suggest `f{char}`/`t{char}`.
* If a word was replaced via `v` selection + `c` → suggest `ciw`.

And a tiny UI helper to show a floating window in the top-right.

# Why not “just Lua” vs Rust?

* **Start in Lua**. It’s fast enough for small windows and heuristics.
* If you later do heavier **diff + AST** classification over wider ranges, a Rust helper (via `nvim-oxi`) with `ropey` (text) and a Myers diff implementation gives more headroom. Keep that behind an async call so it never janks the UI.

# Prior art & differentiation

* There are plugins that **discourage** inefficient keys or **show keymaps** (e.g., which-key, “hard time”–style plugins, practice games). Your angle is unique: **observe intent** via buffer diffs and **teach the one-liner** (operators + motions + textobjects) *for exactly what the user just did*.

# Risks & mitigations

* **Annoyance factor:** make hints rare, actionable, and dismissible; easy global toggle.
* **False positives:** start with conservative rules; show confidence; allow “not useful” feedback to tune thresholds.
* **Perf:** limit snapshots to ±5–10 lines; debounce; optional native helper.

# Name ideas

“nvim-key-coach”, “MotionMentor”, “Sensei”, “VimCoach”.

If you want, I can spin up a minimal plugin scaffold with the key capture, debounce, two rules (`x` spam → `dw`, char-walk → `f/t`), and a clean floating hint. Then we iterate on rules and add Tree-sitter context.
