return {
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    version = false,
    build = vim.fn.has 'win32' ~= 0 and 'powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false'
      or 'make',
    cmd = {
      'AvanteAsk',
      'AvanteBuild',
      'AvanteChat',
      'AvanteChatNew',
      'AvanteClear',
      'AvanteEdit',
      'AvanteFocus',
      'AvanteHistory',
      'AvanteModels',
      'AvanteRefresh',
      'AvanteShowRepoMap',
      'AvanteStop',
      'AvanteSwitchProvider',
      'AvanteSwitchSelectorProvider',
      'AvanteToggle',
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-telescope/telescope.nvim',
      'hrsh7th/nvim-cmp',
      'nvim-tree/nvim-web-devicons',
      { 'stevearc/dressing.nvim', opts = {} },
      'MeanderingProgrammer/render-markdown.nvim',
    },
    opts = {
      provider = 'openrouter',
      providers = {
        openrouter = {
          __inherited_from = 'openai',
          endpoint = 'https://openrouter.ai/api/v1',
          model = vim.env.OPENROUTER_MODEL or 'anthropic/claude-sonnet-4',
          api_key_name = 'OPENROUTER_API_KEY',
          timeout = 30000,
          extra_request_body = {
            temperature = 0.3,
            max_tokens = 8192,
          },
        },
      },
      input = {
        provider = 'dressing',
      },
      selector = {
        provider = 'telescope',
      },
    },
    keys = {
      { '<leader>aa', '<cmd>AvanteAsk<cr>', mode = { 'n', 'v' }, desc = 'Avante: Ask' },
      { '<leader>ac', '<cmd>AvanteChat<cr>', desc = 'Avante: Chat' },
      { '<leader>an', '<cmd>AvanteChatNew<cr>', desc = 'Avante: New chat' },
      { '<leader>ae', '<cmd>AvanteEdit<cr>', mode = { 'n', 'v' }, desc = 'Avante: Edit selection' },
      { '<leader>af', '<cmd>AvanteFocus<cr>', desc = 'Avante: Focus' },
      { '<leader>at', '<cmd>AvanteToggle<cr>', desc = 'Avante: Toggle' },
      { '<leader>as', '<cmd>AvanteStop<cr>', desc = 'Avante: Stop' },
      { '<leader>am', '<cmd>AvanteModels<cr>', desc = 'Avante: Models' },
      { '<leader>ap', '<cmd>AvanteSwitchProvider<cr>', desc = 'Avante: Switch provider' },
      { '<leader>ar', '<cmd>AvanteShowRepoMap<cr>', desc = 'Avante: Repo map' },
    },
  },
}
