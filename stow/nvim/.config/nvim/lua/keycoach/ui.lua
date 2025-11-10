local U = {}
local logger = require('keycoach.logger')

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
    if #l > maxw then
      l = l:sub(1, maxw - 1) .. '…'
    end
    table.insert(out, l)
  end
  return out
end

function U.hint(text, subtitle)
  if type(text) ~= 'string' then return end
  
  logger.log('UI', 'Showing hint', { text = text, subtitle = subtitle })
  
  local lines = {}
  
  -- Handle multi-line text (for stats)
  if text:match('\n') then
    for line in text:gmatch('[^\n]+') do
      table.insert(lines, line)
    end
  else
    lines = { 'KeyCoach', text }
    if subtitle and subtitle ~= '' then
      table.insert(lines, subtitle)
    end
  end
  
  lines = truncate_lines(lines, 68)
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  
  -- Calculate width and height
  local width = 2
  for _, l in ipairs(lines) do
    width = math.max(width, #l + 2)
  end
  local height = #lines
  
  local opts = place_top_right(buf, width, height)
  local win = vim.api.nvim_open_win(buf, false, opts)
  
  -- Style the window
  vim.api.nvim_set_option_value('winblend', 20, { win = win })
  vim.api.nvim_set_option_value('wrap', false, { win = win })
  
  logger.log('UI', 'Hint window created', { width = width, height = height, win = win })
  
  -- Auto-close after a short time
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
      logger.log('UI', 'Hint window closed')
    end
  end, 2500) -- 2.5 seconds
end

return U

