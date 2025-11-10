local L = {}
local config = require('keycoach.config')

local enabled = false
local log_buffer = {}
local max_log_entries = 100

-- Enable/disable logging
function L.set_enabled(value)
  enabled = value or false
end

function L.is_enabled()
  -- Check config first, then local enabled state
  return config.get_value('logging_enabled') or enabled
end

function L.should_notify()
  return config.get_value('logging_notify') or false
end

-- Log a message with a tag
function L.log(tag, message, data)
  if not L.is_enabled() then return end
  
  local timestamp = os.date('%H:%M:%S')
  local entry = {
    time = timestamp,
    tag = tag,
    msg = message,
    data = data,
  }
  
  table.insert(log_buffer, entry)
  
  -- Keep only last N entries
  if #log_buffer > max_log_entries then
    table.remove(log_buffer, 1)
  end
  
  -- Only notify if configured to do so (to avoid interrupting editing)
  if L.should_notify() then
    local log_line = string.format('[KeyCoach:%s] %s', tag, message)
    if data then
      -- Truncate long data for display
      local ok, data_str = pcall(function() return vim.inspect(data) end)
      if ok then
        if #data_str > 200 then
          data_str = data_str:sub(1, 200) .. '...'
        end
        log_line = log_line .. ' | ' .. data_str
      else
        log_line = log_line .. ' | [data inspection failed]'
      end
    end
    -- Use pcall to avoid breaking if notify fails
    pcall(function() vim.notify(log_line, vim.log.levels.INFO) end)
  end
end

-- Get all log entries
function L.get_logs()
  return log_buffer
end

-- Clear logs
function L.clear()
  log_buffer = {}
end

-- Format logs as a string
function L.format_logs()
  if #log_buffer == 0 then
    return 'No logs yet. Enable logging with :KeyCoachLogEnable'
  end
  
  local lines = { 'KeyCoach Logs:', '' }
  for _, entry in ipairs(log_buffer) do
    local line = string.format('[%s] [%s] %s', entry.time, entry.tag, entry.msg)
    if entry.data then
      line = line .. '\n  ' .. vim.inspect(entry.data):gsub('\n', '\n  ')
    end
    table.insert(lines, line)
  end
  return table.concat(lines, '\n')
end

-- Show logs in a floating window
function L.show_logs()
  local logs = L.format_logs()
  local lines = {}
  for line in logs:gmatch('[^\n]+') do
    table.insert(lines, line)
  end
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  
  local width = math.min(120, vim.api.nvim_get_option_value('columns', {}) - 4)
  local height = math.min(#lines + 2, vim.api.nvim_get_option_value('lines', {}) - 4)
  
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = 2,
    col = 2,
    style = 'minimal',
    border = 'rounded',
    noautocmd = true,
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_set_option_value('wrap', true, { win = win })
  vim.api.nvim_set_option_value('number', false, { win = win })
  
  -- Add keymap to close with 'q'
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close<cr>', { noremap = true, silent = true })
  
  -- Set filetype for better syntax if desired
  vim.api.nvim_set_option_value('filetype', 'keycoach-logs', { buf = buf })
end

-- Copy logs to clipboard
function L.copy_logs()
  local logs = L.format_logs()
  
  -- Try to use system clipboard
  local success = false
  
  -- Try using vim.fn.setreg with '+' register (system clipboard)
  if vim.fn.has('clipboard') == 1 then
    vim.fn.setreg('+', logs)
    success = true
  end
  
  -- Also try using xclip/xsel on Linux
  if not success then
    local handle = io.popen('which xclip 2>/dev/null')
    if handle then
      local xclip_exists = handle:read('*a')
      handle:close()
      if xclip_exists and xclip_exists ~= '' then
        local pipe = io.popen('xclip -selection clipboard', 'w')
        if pipe then
          pipe:write(logs)
          pipe:close()
          success = true
        end
      end
    end
  end
  
  -- Fallback: try xsel
  if not success then
    local handle = io.popen('which xsel 2>/dev/null')
    if handle then
      local xsel_exists = handle:read('*a')
      handle:close()
      if xsel_exists and xsel_exists ~= '' then
        local pipe = io.popen('xsel --clipboard --input', 'w')
        if pipe then
          pipe:write(logs)
          pipe:close()
          success = true
        end
      end
    end
  end
  
  if success then
    vim.notify('KeyCoach logs copied to clipboard!', vim.log.levels.INFO)
  else
    -- Fallback: copy to unnamed register and show message
    vim.fn.setreg('"', logs)
    vim.notify('KeyCoach logs copied to unnamed register (use "p to paste). Clipboard copy failed - install xclip or xsel for clipboard support.', vim.log.levels.WARN)
  end
end

return L

