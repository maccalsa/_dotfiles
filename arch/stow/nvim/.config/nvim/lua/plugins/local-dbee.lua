-- <leader>D* avoids LazyVim DAP's <leader>db (toggle breakpoint).
return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>D", group = "database" },
      },
    },
  },
  {
    "kndndrj/nvim-dbee",
    cmd = "Dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = 'mkdir -p "$HOME/.local/share/nvim/dbee/bin" && go build -C dbee -o "$HOME/.local/share/nvim/dbee/bin/dbee"',
    config = function()
      local sources = require("dbee.sources")

      require("dbee").setup({
        sources = {
          sources.EnvSource:new("DBEE_CONNECTIONS"),
          sources.FileSource:new(vim.fn.stdpath("data") .. "/dbee/connections.json"),
        },
      })
    end,
    keys = {
      { "<leader>Dt", "<cmd>Dbee toggle<cr>", desc = "Database: Toggle DBee" },
      { "<leader>Do", "<cmd>Dbee open<cr>", desc = "Database: Open DBee" },
      { "<leader>Dc", "<cmd>Dbee close<cr>", desc = "Database: Close DBee" },
    },
  },
}
