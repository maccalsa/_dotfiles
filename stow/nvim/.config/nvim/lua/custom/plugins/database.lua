return {
  {
    'kndndrj/nvim-dbee',
    cmd = 'Dbee',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    build = 'mkdir -p "$HOME/.local/share/nvim/dbee/bin" && go build -C dbee -o "$HOME/.local/share/nvim/dbee/bin/dbee"',
    config = function()
      local sources = require 'dbee.sources'

      require('dbee').setup {
        sources = {
          sources.EnvSource:new 'DBEE_CONNECTIONS',
          sources.FileSource:new(vim.fn.stdpath 'data' .. '/dbee/connections.json'),
        },
      }
    end,
    keys = {
      { '<leader>db', '<cmd>Dbee toggle<cr>', desc = 'Database: Toggle DBee' },
      { '<leader>do', '<cmd>Dbee open<cr>', desc = 'Database: Open DBee' },
      { '<leader>dc', '<cmd>Dbee close<cr>', desc = 'Database: Close DBee' },
    },
  },
}
