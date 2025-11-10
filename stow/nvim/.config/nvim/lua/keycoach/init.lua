local M = {}

local ns = vim.api.nvim_create_namespace('keycoach')
local enabled = false

local state = {
  keys = {},
  last_tick = {},
  timer = nil,
  counters = {
    rule_x_spam = 0,
    rule_hl_walk = 0,
    rule_visual_replace = 0,
    rule_manual_join = 0,
    rule_case_change = 0,
    rule_indent_manual = 0,
    rule_repeat_opportunity = 0,
    rule_text_object_hint = 0,
  },
  before_snapshot = nil,
  last_hint_time = 0,
  hint_cooldown = 2000, -- 2 seconds between hints
}

-- Check if we're in a context where coaching makes sense
local function in_coachable_context()
  local m = vim.api.nvim_get_mode().mode
  -- Only normal and visual modes
  if not m:match('^[nv]') then return false end
  
  -- Avoid terminals, prompts, help, quickfix, etc.
  local bt = vim.bo.buftype
  if bt ~= '' and bt ~= 'acwrite' then return false end
  if vim.tbl_contains({ 'help', 'terminal', 'nofile', 'prompt', 'quickfix' }, bt) then return false end
  
  -- Never interrupt macros
  if vim.fn.reg_recording() ~= '' then return false end
  
  -- Only normal mode for key capture (visual mode is handled differently)
  if m ~= 'n' then return false end
  
  return true
end

local function reset_keys()
  state.keys = {}
end

-- Snapshot buffer state before changes
local function snapshot_before()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local from_line = math.max(0, row - 6)
  local to_line = row + 5
  local lines = vim.api.nvim_buf_get_lines(bufnr, from_line, to_line, false)
  return {
    bufnr = bufnr,
    row = row,
    from = from_line,
    to = to_line,
    lines = lines,
    tick = vim.b.changedtick or 0,
  }
end

-- Snapshot buffer state after changes
local function snapshot_after()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local from_line = math.max(0, row - 6)
  local to_line = row + 5
  local lines = vim.api.nvim_buf_get_lines(bufnr, from_line, to_line, false)
  return {
    bufnr = bufnr,
    row = row,
    from = from_line,
    to = to_line,
    lines = lines,
    tick = vim.b.changedtick or 0,
  }
end

-- Analyze changes and show suggestion
local function on_pause_after_change()
  if not enabled then return end
  
  local after = snapshot_after()
  local before = state.before_snapshot
  
  if not before or before.bufnr ~= after.bufnr then
    state.before_snapshot = nil
    reset_keys()
    return
  end
  
  -- Rate limiting: don't spam hints
  local now = vim.loop.now()
  if now - state.last_hint_time < state.hint_cooldown then
    reset_keys()
    state.before_snapshot = nil
    return
  end
  
  local suggestion = require('keycoach.rules').suggest(state.keys, before, after)
  reset_keys()
  state.before_snapshot = nil
  
  if suggestion then
    -- Update counter
    if state.counters[suggestion.key] then
      state.counters[suggestion.key] = state.counters[suggestion.key] + 1
    end
    
    -- Show hint
    require('keycoach.ui').hint(suggestion.text, suggestion.example)
    state.last_hint_time = now
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

-- Capture keystrokes
local function on_key(key)
  if not enabled then return end
  if not in_coachable_context() then return end
  
  -- Store snapshot before first key if we don't have one
  if not state.before_snapshot then
    state.before_snapshot = snapshot_before()
  end
  
  table.insert(state.keys, { key = key, t = vim.loop.now() })
end

-- Handle buffer changes
local function on_text_changed()
  if not enabled then return end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local tick = vim.b.changedtick or 0
  
  -- Skip if no actual change
  if state.last_tick[bufnr] and tick == state.last_tick[bufnr] then return end
  state.last_tick[bufnr] = tick
  
  -- Wait for user to pause before analyzing
  -- Note: before_snapshot should already be captured by on_key for normal mode edits
  arm_debounce(350)
end

function M.enable()
  if enabled then return end
  enabled = true
  reset_keys()
  state.last_tick = {}
  state.before_snapshot = nil
  
  -- Capture keys
  vim.on_key(on_key, ns)
  
  -- Watch for buffer changes
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = vim.api.nvim_create_augroup('KeyCoachChanged', { clear = true }),
    callback = on_text_changed,
  })
end

function M.disable()
  if not enabled then return end
  enabled = false
  reset_keys()
  state.before_snapshot = nil
  
  if state.timer then
    state.timer:stop()
  end
  
  vim.on_key(nil, ns)
  pcall(vim.api.nvim_del_augroup_by_name, 'KeyCoachChanged')
end

function M.toggle()
  if enabled then
    M.disable()
    vim.notify('KeyCoach disabled', vim.log.levels.INFO)
  else
    M.enable()
    vim.notify('KeyCoach enabled', vim.log.levels.INFO)
  end
end

function M.stats()
  local lines = {
    'KeyCoach Stats:',
    '',
    ('  x/dl spam → dw/daw: %d'):format(state.counters.rule_x_spam),
    ('  h/l walking → f/t/w/b: %d'):format(state.counters.rule_hl_walk),
    ('  visual replace → ciw/ci(: %d'):format(state.counters.rule_visual_replace),
    ('  manual join → J/gJ: %d'):format(state.counters.rule_manual_join),
    ('  case change → gUw/guw: %d'):format(state.counters.rule_case_change),
    ('  manual indent → >ip/<ip: %d'):format(state.counters.rule_indent_manual),
    ('  repeat opportunity → .: %d'):format(state.counters.rule_repeat_opportunity),
    ('  text object hint → ci"/ci(: %d'):format(state.counters.rule_text_object_hint),
  }
  require('keycoach.ui').hint(table.concat(lines, '\n'))
end

-- Create user commands
vim.api.nvim_create_user_command('KeyCoachToggle', M.toggle, { desc = 'Toggle KeyCoach on/off' })
vim.api.nvim_create_user_command('KeyCoachStats', M.stats, { desc = 'Show KeyCoach statistics' })

return M

