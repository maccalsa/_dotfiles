-- Custom plugins (Alpha dashboard is in issue_mode.lua)
-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  'onsails/lspkind.nvim',
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {},
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  },
  {
    -- Install markdown preview, use npx if available.
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function(plugin)
      if vim.fn.executable 'npx' then
        vim.cmd('!cd ' .. plugin.dir .. ' && cd app && npx --yes yarn install')
      else
        vim.cmd [[Lazy load markdown-preview.nvim]]
        vim.fn['mkdp#util#install']()
      end
    end,
    init = function()
      if vim.fn.executable 'npx' then
        vim.g.mkdp_filetypes = { 'markdown' }
      end
    end,
  },
  {
    'gelguy/wilder.nvim',
    lazy = true,
    config = function() end,
  },
  -- {
  --   'tpope/vim-fugitive',
  -- },
  {
    'nvimtools/none-ls.nvim',
    config = function()
      local null_ls = require 'null-ls'
      null_ls.setup {
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.prettier,
          null_ls.builtins.diagnostics.erb_lint,
          null_ls.builtins.diagnostics.rubocop,
          null_ls.builtins.formatting.rubocop,
        },
      }

      vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format, { desc = 'Format buffer' })
    end,
  },
  -- {
  --   'stevearc/oil.nvim',
  --   config = function()
  --     local oil = require 'oil'
  --     oil.setup()
  --     vim.keymap.set('n', '-', oil.toggle_float, {})
  --   end,
  -- },
  {
    'kdheepak/lazygit.nvim',
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'Open lazy git' },
    },
  },
  {
    'fedepujol/move.nvim',
    config = function()
      require('move').setup {}
    end,
  },
  -- Alpha dashboard moved to issue_mode.lua (issue-mode layout)
  {
    -- KeyCoach: Learn Vim motions by observing your editing patterns
    -- Local plugin - loads from lua/keycoach/ and plugin/keycoach.lua
    dir = vim.fn.stdpath('config'),
    name = 'keycoach',
    lazy = false, -- Load immediately on startup
    config = function()
      -- Setup with default config (enabled=true, logging_enabled=false)
      -- You can customize this by calling require('keycoach').setup({ ... })
      require('keycoach').setup({
        enabled = true,          -- KeyCoach enabled by default
        logging_enabled = false, -- Logging disabled by default (to avoid interrupting editing)
        logging_notify = false,  -- Don't show notifications for logs
        hint_cooldown = 2000,    -- 2 seconds between hints
      })
      -- Initialize (will auto-enable if config.enabled is true)
      require('keycoach')._init()
    end,
  },

  --   {
  --     "goolord/alpha-nvim",
  --     dependencies = {
  --       "nvim-tree/nvim-web-devicons",
  --     },

  -- config = function()
  --   local alpha = require("alpha")
  --   local dashboard = require("alpha.themes.startify")

  --   dashboard.section.header.val = {
  --     [[                                                                       ]],
  --     [[                                                                       ]],
  --     [[                                                                       ]],
  --     [[                                                                       ]],
  --     [[                                                                     ]],
  --     [[       ████ ██████           █████      ██                     ]],
  --     [[      ███████████             █████                             ]],
  --     [[      █████████ ███████████████████ ███   ███████████   ]],
  --     [[     █████████  ███    █████████████ █████ ██████████████   ]],
  --     [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
  --     [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
  --     [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
  --     [[                                                                       ]],
  --     [[                                                                       ]],
  --     [[                                                                       ]],
  --   }

  --   alpha.setup(dashboard.opts)
  -- end,
  -- },

  --   {
  --     {
  --       "catppuccin/nvim",
  --       lazy = false,
  --       name = "catppuccin",
  --       priority = 1000,
  --       config = function()
  --         vim.cmd.colorscheme "catppuccin-mocha"
  --       end
  --     }
  --   }
}
