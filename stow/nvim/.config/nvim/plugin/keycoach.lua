-- KeyCoach plugin entry point
-- This file is loaded automatically by Neovim when the plugin is on runtimepath
if vim.g.loaded_keycoach then return end
vim.g.loaded_keycoach = true

-- Commands are created in the module itself, but we ensure the module is loaded
-- The actual enabling happens via lazy.nvim config

