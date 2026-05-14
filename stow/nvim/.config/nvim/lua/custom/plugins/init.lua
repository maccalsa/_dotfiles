-- Custom plugins (Alpha dashboard is in issue_mode.lua)
-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  'onsails/lspkind.nvim',
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {
      file_types = { 'markdown', 'Avante' },
    },
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
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    lazy = false,
    config = function()
      require('toggleterm').setup {
        size = 15,
        open_mapping = false,
        direction = 'float', -- Floating window (dialog-like) instead of split
        start_in_insert = true,
        shade_terminals = true,
        persist_mode = true,
        insert_mappings = true,
        terminal_mappings = true,
        close_on_exit = true,
        float_opts = { border = 'single' },
      }
      -- Keymaps using Lua API (commands may not exist in some setups)
      vim.keymap.set('n', '<leader>tt', function() require('toggleterm').toggle() end, { desc = 'Toggle terminal' })
      vim.keymap.set('n', '<leader>t1', function() require('toggleterm').toggle(1) end, { desc = 'Toggle terminal 1' })
      vim.keymap.set('n', '<leader>t2', function() require('toggleterm').toggle(2) end, { desc = 'Toggle terminal 2' })
      vim.keymap.set('n', '<leader>t3', function() require('toggleterm').toggle(3) end, { desc = 'Toggle terminal 3' })
      vim.keymap.set('n', '<leader>tn', function()
        local terms = require('toggleterm.terminal').get_all(true)
        local max_id = 0
        for _, t in ipairs(terms) do
          if t.id > max_id then max_id = t.id end
        end
        require('toggleterm').toggle(max_id + 1)
      end, { desc = 'New terminal' })
      vim.keymap.set('n', '<leader>ts', function()
        local terms = require('toggleterm.terminal').get_all(true)
        if #terms == 0 then
          vim.notify('No terminals yet. Use <leader>tt or <leader>tn to create one.', vim.log.levels.INFO)
          return
        end
        vim.ui.select(terms, {
          prompt = 'Select terminal: ',
          format_item = function(t) return t.id .. ': ' .. t:_display_name() end,
        }, function(term)
          if term then
            if term:is_open() then term:focus() else term:open() end
          end
        end)
      end, { desc = 'Select terminal' })
      vim.keymap.set('n', '<leader>ta', function() require('toggleterm').toggle_all() end,
        { desc = 'Toggle all terminals' })
      vim.keymap.set('n', '<leader>tk', function()
        if vim.bo.buftype == 'terminal' then
          vim.cmd('bdelete!')
        else
          vim.notify('Not in a terminal buffer', vim.log.levels.WARN)
        end
      end, { desc = 'Kill current terminal' })

      local function gradle_root()
        local current_file = vim.api.nvim_buf_get_name(0)
        local start_path = current_file ~= '' and vim.fs.dirname(current_file) or vim.uv.cwd()
        local marker = vim.fs.find({ 'gradlew', 'settings.gradle.kts', 'settings.gradle', 'build.gradle.kts', 'build.gradle' }, {
          path = start_path,
          upward = true,
        })[1]

        return marker and vim.fs.dirname(marker) or nil
      end

      local function parse_gradle_tasks(input)
        local tasks = {}
        for task in input:gmatch '%S+' do
          if not task:match '^[%w_:%.-]+$' then
            vim.notify('Gradle task contains unsupported characters: ' .. task, vim.log.levels.ERROR)
            return nil
          end
          table.insert(tasks, task)
        end

        return #tasks > 0 and tasks or nil
      end

      local function run_gradle(input)
        local root = gradle_root()
        if not root then
          vim.notify('No Gradle project found from the current buffer.', vim.log.levels.WARN)
          return
        end

        local tasks = parse_gradle_tasks(input)
        if not tasks then
          return
        end

        local wrapper = root .. '/gradlew'
        local executable = vim.fn.executable(wrapper) == 1 and './gradlew' or 'gradle'
        require('toggleterm.terminal').Terminal:new({
          cmd = executable .. ' ' .. table.concat(tasks, ' '),
          dir = root,
          direction = 'float',
          close_on_exit = false,
          hidden = true,
        }):toggle()
      end

      local function show_lsp_clients()
        local clients = vim.lsp.get_clients { bufnr = 0 }
        if #clients == 0 then
          vim.notify('No LSP clients attached to this buffer.', vim.log.levels.WARN)
          return
        end

        local names = vim.tbl_map(function(client)
          return client.name
        end, clients)
        vim.notify('Attached LSP clients: ' .. table.concat(names, ', '), vim.log.levels.INFO)
      end

      vim.keymap.set('n', '<leader>Kr', function() run_gradle 'bootRun' end, { desc = 'Kotlin/Spring: Boot run' })
      vim.keymap.set('n', '<leader>Kt', function() run_gradle 'test' end, { desc = 'Kotlin/Spring: Test' })
      vim.keymap.set('n', '<leader>Kb', function() run_gradle 'build' end, { desc = 'Kotlin/Spring: Build' })
      vim.keymap.set('n', '<leader>Kc', function() run_gradle 'clean' end, { desc = 'Kotlin/Spring: Clean' })
      vim.keymap.set('n', '<leader>Ki', show_lsp_clients, { desc = 'Kotlin/Spring: LSP clients' })
      vim.keymap.set('n', '<leader>Kx', function()
        vim.ui.input({ prompt = 'Gradle task(s): ' }, function(input)
          if input and input ~= '' then
            run_gradle(input)
          end
        end)
      end, { desc = 'Kotlin/Spring: Run Gradle task' })

      -- Exit terminal mode: Esc or Ctrl-\ Ctrl-n (built-in). Add toggleterm-specific mapping.
      vim.api.nvim_create_autocmd('TermOpen', {
        pattern = { 'term://*#toggleterm#*', 'term://*::toggleterm::*' },
        callback = function()
          vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { buffer = 0, desc = 'Exit terminal mode' })
          vim.keymap.set('t', '<C-h>', '<Cmd>wincmd h<CR>', { buffer = 0, desc = 'Focus left window' })
          vim.keymap.set('t', '<C-j>', '<Cmd>wincmd j<CR>', { buffer = 0, desc = 'Focus down window' })
          vim.keymap.set('t', '<C-k>', '<Cmd>wincmd k<CR>', { buffer = 0, desc = 'Focus up window' })
          vim.keymap.set('t', '<C-l>', '<Cmd>wincmd l<CR>', { buffer = 0, desc = 'Focus right window' })
        end,
      })
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
        enabled = false,         -- Disabled (was: true)
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
