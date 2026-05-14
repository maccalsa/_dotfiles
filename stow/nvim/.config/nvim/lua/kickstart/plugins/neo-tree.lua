-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

local function is_regular_file(path)
  local stat = path and vim.uv.fs_stat(path) or nil
  return stat and stat.type == 'file'
end

local function is_inside_cwd(path)
  local cwd = vim.fs.normalize(vim.uv.cwd() or '')
  local normalized = vim.fs.normalize(path)
  return normalized == cwd or normalized:sub(1, #cwd + 1) == cwd .. '/'
end

local function reveal_current_file()
  local command = require 'neo-tree.command'
  local path = vim.api.nvim_buf_get_name(0)

  if is_regular_file(path) and is_inside_cwd(path) then
    command.execute {
      action = 'focus',
      source = 'filesystem',
      position = 'left',
      reveal_file = path,
    }
    return
  end

  command.execute {
    action = 'focus',
    source = 'filesystem',
    position = 'left',
  }
end

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = { 'Neotree', 'NeotreeFollowToggle' },
  keys = {
    { '\\', reveal_current_file, desc = 'NeoTree reveal current file' },
    { '<leader>nt', '<cmd>Neotree toggle left<cr>', desc = 'NeoTree toggle' },
    { '<leader>nf', '<cmd>NeotreeFollowToggle<cr>', desc = 'NeoTree follow current file' },
  },
  opts = {
    filesystem = {
      hijack_netrw_behavior = 'open_current',
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
  config = function(_, opts)
    require('neo-tree').setup(opts)

    local follow_current_file = false

    local function follow_file()
      local path = vim.api.nvim_buf_get_name(0)
      if not is_regular_file(path) or not is_inside_cwd(path) then
        return
      end

      reveal_current_file()
    end

    vim.api.nvim_create_user_command('NeotreeFollowToggle', function()
      follow_current_file = not follow_current_file
      vim.notify('Neo-tree follow current file: ' .. (follow_current_file and 'enabled' or 'disabled'), vim.log.levels.INFO)
      if follow_current_file then
        follow_file()
      end
    end, {})

    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('custom-neotree-follow', { clear = true }),
      callback = function()
        if follow_current_file then
          follow_file()
        end
      end,
    })
  end,
}
