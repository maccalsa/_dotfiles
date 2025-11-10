local M = {}
local logger = require('keycoach.logger')
local config = require('keycoach.config')

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
  hint_cooldown = config.get_value('hint_cooldown'),
}

-- Setup function for user configuration
function M.setup(user_config)
  config.setup(user_config)
  -- Update hint_cooldown if changed
  state.hint_cooldown = config.get_value('hint_cooldown')
  -- Initialize logging state from config
  if config.get_value('logging_enabled') then
    logger.set_enabled(true)
  end
end

-- Check if we're in a context where coaching makes sense
local function in_coachable_context()
  local m = vim.api.nvim_get_mode().mode
  -- Only normal and visual modes
  if not m:match('^[nv]') then
    logger.log('CONTEXT', 'Skipping: not in normal/visual mode', { mode = m })
    return false
  end
  
  -- Avoid terminals, prompts, help, quickfix, etc.
  local bt = vim.bo.buftype
  if bt ~= '' and bt ~= 'acwrite' then
    logger.log('CONTEXT', 'Skipping: special buftype', { buftype = bt })
    return false
  end
  if vim.tbl_contains({ 'help', 'terminal', 'nofile', 'prompt', 'quickfix' }, bt) then
    logger.log('CONTEXT', 'Skipping: excluded buftype', { buftype = bt })
    return false
  end
  
  -- Never interrupt macros
  local recording = vim.fn.reg_recording()
  if recording ~= '' then
    logger.log('CONTEXT', 'Skipping: macro recording', { reg = recording })
    return false
  end
  
  -- Only normal mode for key capture (visual mode is handled differently)
  if m ~= 'n' then
    logger.log('CONTEXT', 'Skipping: not normal mode', { mode = m })
    return false
  end
  
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
  
  logger.log('ANALYZE', 'Starting analysis after pause')
  
  local after = snapshot_after()
  local before = state.before_snapshot
  
  if not before or before.bufnr ~= after.bufnr then
    logger.log('ANALYZE', 'Skipping: no before snapshot or buffer mismatch', {
      has_before = before ~= nil,
      before_bufnr = before and before.bufnr or nil,
      after_bufnr = after.bufnr,
    })
    state.before_snapshot = nil
    reset_keys()
    return
  end
  
  -- Rate limiting: don't spam hints
  local now = vim.loop.now()
  if now - state.last_hint_time < state.hint_cooldown then
    local time_since = now - state.last_hint_time
    logger.log('ANALYZE', 'Skipping: rate limited', {
      time_since_last = time_since,
      cooldown = state.hint_cooldown,
    })
    reset_keys()
    state.before_snapshot = nil
    return
  end
  
  logger.log('ANALYZE', 'Evaluating rules', {
    num_keys = #state.keys,
    before_tick = before.tick,
    after_tick = after.tick,
    before_row = before.row,
    after_row = after.row,
  })
  
  local suggestion = require('keycoach.rules').suggest(state.keys, before, after)
  reset_keys()
  state.before_snapshot = nil
  
  if suggestion then
    logger.log('ANALYZE', 'Suggestion found', {
      rule = suggestion.key,
      score = suggestion.score,
      text = suggestion.text,
      example = suggestion.example,
    })
    
    -- Update counter
    if state.counters[suggestion.key] then
      state.counters[suggestion.key] = state.counters[suggestion.key] + 1
    end
    
    -- Show hint
    require('keycoach.ui').hint(suggestion.text, suggestion.example)
    state.last_hint_time = now
  else
    logger.log('ANALYZE', 'No suggestion matched')
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

-- Analyze keys even without buffer changes (for movement-only rules)
local movement_timer = nil
local function analyze_movement_keys()
  if not enabled then return end
  if #state.keys == 0 then return end
  
  -- Only analyze if we have enough keys and haven't shown a hint recently
  local now = vim.loop.now()
  if now - state.last_hint_time < state.hint_cooldown then
    return
  end
  
  -- Check if we have a before snapshot (means user started doing something)
  if not state.before_snapshot then return end
  
  -- For movement-only rules, we can analyze without buffer changes
  -- Create a dummy after snapshot from before (no changes)
  local before = state.before_snapshot
  local after = {
    bufnr = before.bufnr,
    row = vim.api.nvim_win_get_cursor(0)[1],
    from = before.from,
    to = before.to,
    lines = vim.deepcopy(before.lines),
    tick = before.tick,
  }
  
  logger.log('ANALYZE', 'Analyzing movement keys (no buffer change)', {
    num_keys = #state.keys,
  })
  
  local suggestion = require('keycoach.rules').suggest(state.keys, before, after)
  
  if suggestion and suggestion.key == 'rule_hl_walk' then
    -- Only show movement hints if it's a movement rule
    logger.log('ANALYZE', 'Movement suggestion found', {
      rule = suggestion.key,
      score = suggestion.score,
    })
    
    if state.counters[suggestion.key] then
      state.counters[suggestion.key] = state.counters[suggestion.key] + 1
    end
    
    require('keycoach.ui').hint(suggestion.text, suggestion.example)
    state.last_hint_time = now
    reset_keys()
    state.before_snapshot = nil
  end
end

-- Capture keystrokes
local function on_key(key)
  if not enabled then return end
  if not in_coachable_context() then return end
  
  -- Store snapshot before first key if we don't have one
  if not state.before_snapshot then
    state.before_snapshot = snapshot_before()
    logger.log('KEY', 'Captured before snapshot', {
      bufnr = state.before_snapshot.bufnr,
      row = state.before_snapshot.row,
      tick = state.before_snapshot.tick,
    })
  end
  
  table.insert(state.keys, { key = key, t = vim.loop.now() })
  logger.log('KEY', 'Key captured', {
    key = key:gsub('%c', function(c) return string.format('\\x%02x', string.byte(c)) end),
    total_keys = #state.keys,
    keys_so_far = vim.tbl_map(function(k)
      return k.key:gsub('%c', function(c) return string.format('\\x%02x', string.byte(c)) end)
    end, state.keys),
  })
  
  -- For movement keys (h/l), also check after a pause even without buffer changes
  -- Cancel previous timer and start a new one
  if movement_timer then
    movement_timer:stop()
  end
  movement_timer = vim.loop.new_timer()
  movement_timer:start(500, 0, vim.schedule_wrap(function()
    analyze_movement_keys()
  end))
end

-- Handle buffer changes
local function on_text_changed()
  if not enabled then return end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local tick = vim.b.changedtick or 0
  
  -- Skip if no actual change
  if state.last_tick[bufnr] and tick == state.last_tick[bufnr] then
    logger.log('CHANGE', 'Skipping: same tick', { bufnr = bufnr, tick = tick })
    return
  end
  
  logger.log('CHANGE', 'Buffer changed detected', {
    bufnr = bufnr,
    tick = tick,
    last_tick = state.last_tick[bufnr],
    keys_captured = #state.keys,
    has_before_snapshot = state.before_snapshot ~= nil,
  })
  
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
  
  logger.log('SYSTEM', 'KeyCoach enabled')
  
  -- Capture keys
  vim.on_key(on_key, ns)
  
  -- Watch for buffer changes
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = vim.api.nvim_create_augroup('KeyCoachChanged', { clear = true }),
    callback = on_text_changed,
  })
end

-- Initialize from config on load
function M._init()
  -- Set logging state from config
  if config.get_value('logging_enabled') then
    logger.set_enabled(true)
  end
  
  -- Auto-enable if configured
  if config.get_value('enabled') then
    -- Use schedule to ensure Neovim is fully initialized
    vim.schedule(function()
      M.enable()
    end)
  end
end

function M.disable()
  if not enabled then return end
  enabled = false
  reset_keys()
  state.before_snapshot = nil
  
  logger.log('SYSTEM', 'KeyCoach disabled')
  
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

-- Logging commands
function M.log_enable()
  logger.set_enabled(true)
  vim.notify('KeyCoach logging enabled', vim.log.levels.INFO)
end

function M.log_disable()
  logger.set_enabled(false)
  vim.notify('KeyCoach logging disabled', vim.log.levels.INFO)
end

function M.log_show()
  logger.show_logs()
end

function M.log_copy()
  logger.copy_logs()
end

function M.log_clear()
  logger.clear()
  vim.notify('KeyCoach logs cleared', vim.log.levels.INFO)
end

-- Create user commands
vim.api.nvim_create_user_command('KeyCoachToggle', M.toggle, { desc = 'Toggle KeyCoach on/off' })
vim.api.nvim_create_user_command('KeyCoachStats', M.stats, { desc = 'Show KeyCoach statistics' })
vim.api.nvim_create_user_command('KeyCoachLogEnable', M.log_enable, { desc = 'Enable KeyCoach logging' })
vim.api.nvim_create_user_command('KeyCoachLogDisable', M.log_disable, { desc = 'Disable KeyCoach logging' })
vim.api.nvim_create_user_command('KeyCoachLogShow', M.log_show, { desc = 'Show KeyCoach logs' })
vim.api.nvim_create_user_command('KeyCoachLogCopy', M.log_copy, { desc = 'Copy KeyCoach logs to clipboard' })
vim.api.nvim_create_user_command('KeyCoachLogClear', M.log_clear, { desc = 'Clear KeyCoach logs' })

return M

