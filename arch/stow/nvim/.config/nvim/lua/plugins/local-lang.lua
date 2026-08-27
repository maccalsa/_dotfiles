-- Language overrides on top of Omarchy LazyVim.
-- Language extras themselves live in lazyvim.json so LazyVim can import them
-- before lua/plugins/ (required import order).
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        kotlin_lsp = {
          single_file_support = false,
        },
        ols = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "odin" })
    end,
  },
}
