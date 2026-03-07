-- Cheatsheet lookup: fuzzy search NVIM_CHEATSHEET.md and vim-reference.md
local M = {}

local config_dir = vim.fn.stdpath("config")
local CHEATSHEET_FILES = {
  config_dir .. "/NVIM_CHEATSHEET.md",
  config_dir .. "/vim-reference.md",
}

function M.search(opts)
  opts = opts or {}
  local builtin = require("telescope.builtin")
  local actions = require("telescope.actions")

  builtin.live_grep({
    search_dirs = CHEATSHEET_FILES,
    prompt_title = "Cheatsheet Search",
    attach_mappings = opts.open_in_split and function(_, map)
      -- Explicitly map Enter to open in split (overrides default which opens in current window)
      map({ "i", "n" }, "<CR>", actions.file_split)
      return true
    end or nil,
  })
end

return M
