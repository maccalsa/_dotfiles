-- Issue Mode: Telescope pickers, Harpoon, Alpha dashboard
-- Three navigation layers: Telescope (discovery) -> Harpoon (working set) -> Ctrl-^ (last file)
-- Surround: mini.surround (from kickstart/plugins/mini.lua) - sa, sd, sr, sf, sh

return {
  -- Harpoon 2: file bookmarks for 4-6 "issue files" (uses <leader>j to avoid gitsigns <leader>h conflict)
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      vim.keymap.set("n", "<leader>ja", function()
        harpoon:list():add()
      end, { desc = "Harpoon add file" })

      vim.keymap.set("n", "<leader>jh", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Harpoon menu" })

      vim.keymap.set("n", "<leader>j1", function()
        harpoon:list():select(1)
      end, { desc = "Harpoon file 1" })

      vim.keymap.set("n", "<leader>j2", function()
        harpoon:list():select(2)
      end, { desc = "Harpoon file 2" })

      vim.keymap.set("n", "<leader>j3", function()
        harpoon:list():select(3)
      end, { desc = "Harpoon file 3" })

      vim.keymap.set("n", "<leader>j4", function()
        harpoon:list():select(4)
      end, { desc = "Harpoon file 4" })

      vim.keymap.set("n", "<leader>jn", function()
        harpoon:list():next()
      end, { desc = "Harpoon next" })

      vim.keymap.set("n", "<leader>jp", function()
        harpoon:list():prev()
      end, { desc = "Harpoon previous" })
    end,
  },

  -- Extend Telescope with issue-mode keymaps (custom pickers live in lua/issue_mode/)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
      { "<leader>fr", function() require("telescope.builtin").oldfiles() end, desc = "Recent files" },
      { "<leader>gs", function() require("telescope.builtin").git_status() end, desc = "Git status" },
      { "<leader>gm", function() require("issue_mode").open_modified_files() end, desc = "Modified tracked files" },
      { "<leader>gM", function() require("issue_mode").grep_modified_files() end, desc = "Grep modified tracked files" },
      { "<leader>gb", function() require("telescope.builtin").git_branches() end, desc = "Git branches" },
      { "<leader>ch", function() require("cheatsheet").search() end, desc = "[C]heatsheet search (close after)" },
      {
        "<leader>cH",
        function() require("cheatsheet").search({ open_in_split = true }) end,
        desc = "[C]heatsheet search (open in split)",
      },
    },
  },

  -- Alpha dashboard with issue-mode layout (replaces custom Alpha)
  {
    "goolord/alpha-nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "nvim-telescope/telescope.nvim",
      "ThePrimeagen/harpoon",
    },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
        "███╗   ██╗██╗   ██╗██╗███╗   ███╗",
        "████╗  ██║██║   ██║██║████╗ ████║",
        "██╔██╗ ██║██║   ██║██║██╔████╔██║",
        "██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
        "",
        "Issue Mode",
      }

      -- Alpha dashboard.button() expects string keybinds, not callbacks
      dashboard.section.buttons.val = {
        dashboard.button("m", "󰜷  Modified tracked files", "<cmd>lua require('issue_mode').open_modified_files()<CR>"),
        dashboard.button("M", "󰛔  Grep modified tracked files",
          "<cmd>lua require('issue_mode').grep_modified_files()<CR>"),
        dashboard.button("r", "  Recent files", "<cmd>lua require('telescope.builtin').oldfiles()<CR>"),
        dashboard.button("f", "󰈞  Find file", "<cmd>lua require('telescope.builtin').find_files()<CR>"),
        dashboard.button("g", "󰈬  Live grep repo", "<cmd>lua require('telescope.builtin').live_grep()<CR>"),
        dashboard.button("b", "󰓩  Buffers", "<cmd>lua require('telescope.builtin').buffers()<CR>"),
        dashboard.button("s", "  Git status", "<cmd>lua require('telescope.builtin').git_status()<CR>"),
        dashboard.button("h", "󱡀  Harpoon menu",
          "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<CR>"),
        dashboard.button("q", "󰅚  Quit", ":qa<CR>"),
      }

      dashboard.section.footer.val = {
        "",
        "ad dashboard | m modified | M grep modified | h harpoon | Ctrl-^ last file",
      }

      alpha.setup(dashboard.opts)

      vim.keymap.set("n", "<leader>ad", "<cmd>Alpha<CR>", { desc = "Alpha dashboard" })

      -- Show dashboard when using `nvim .` (Alpha normally only shows for `nvim` with no args)
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argc() == 1 and vim.v.argv[2] == "." then
            vim.schedule(function()
              pcall(vim.cmd, "bwipeout")
              pcall(vim.cmd, "Alpha")
            end)
          end
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        callback = function()
          pcall(vim.cmd.AlphaRedraw)
        end,
      })
    end,
  },

  -- which-key groups for issue mode (extends Kickstart's which-key)
  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").add({
        { "<leader>f",  group = "File" },
        { "<leader>g",  group = "Git / issue" },
        { "<leader>j",  group = "Harpoon (jump)" },
        { "<leader>c",  group = "Cheatsheet" },
        { "<leader>ad", desc = "Alpha dashboard" },
      })
    end,
  },
}
