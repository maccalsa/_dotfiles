return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>R", group = "HTTP" },
      },
    },
  },
  {
    "heilgar/nvim-http-client",
    event = "VeryLazy",
    ft = { "http", "rest" },
    cmd = {
      "HttpCopyCurl",
      "HttpDryRun",
      "HttpEnv",
      "HttpEnvFile",
      "HttpGetProjectRoot",
      "HttpProfiling",
      "HttpRun",
      "HttpRunAll",
      "HttpSaveResponse",
      "HttpSetProjectRoot",
      "HttpStop",
      "HttpVerbose",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope.nvim", optional = true },
    },
    config = function()
      require("http_client").setup({
        default_env_file = ".env.json",
        request_timeout = 30000,
        split_direction = "right",
        create_keybindings = true,
        user_agent = "nvim-http-client",
        profiling = {
          enabled = true,
          show_in_response = true,
          detailed_metrics = true,
        },
        keybindings = {
          select_env_file = "<leader>Rf",
          set_env = "<leader>Re",
          run_request = "<leader>Rr",
          stop_request = "<leader>Rx",
          toggle_verbose = "<leader>Rv",
          toggle_profiling = "<leader>Rp",
          dry_run = "<leader>Rd",
          copy_curl = "<leader>Rc",
          save_response = "<leader>Rs",
          set_project_root = "<leader>Rg",
          get_project_root = "<leader>RG",
        },
      })

      pcall(function()
        require("telescope").load_extension("http_client")
      end)

      vim.keymap.set("n", "<leader>Ra", "<cmd>HttpRunAll<cr>", { desc = "HTTP: Run all requests" })
    end,
  },
}
