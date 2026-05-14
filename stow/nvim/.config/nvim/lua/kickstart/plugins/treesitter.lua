local treesitter_parsers = {
  'bash',
  'c',
  'diff',
  'html',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  'heex',
  'groovy',
  'java',
  'kotlin',
  'properties',
}

return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    branch = 'main',
    build = function()
      require('nvim-treesitter').install(treesitter_parsers, { summary = true }):wait(300000)
    end,
    config = function()
      vim.treesitter.language.register('json', 'jsonc')

      local treesitter = require 'nvim-treesitter'
      treesitter.setup()

      if not treesitter.get_installed then
        return
      end

      local installed = treesitter.get_installed 'parsers'
      local missing = vim.tbl_filter(function(parser)
        return not vim.list_contains(installed, parser)
      end, treesitter_parsers)

      if #missing > 0 then
        treesitter.install(missing, { summary = true }):wait(300000)
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
        callback = function()
          if pcall(vim.treesitter.start) then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
