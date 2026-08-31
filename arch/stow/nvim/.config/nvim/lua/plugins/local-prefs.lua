-- Personal prefs on top of Omarchy LazyVim. Loaded after lua/config/options.lua.
-- Do not replace Omarchy files; only override the few defaults we actually want.

-- Omarchy sets relativenumber = false; LazyVim and this overlay prefer relative numbers.
-- Toggle per session with <leader>uL.
vim.opt.relativenumber = true

-- Kickstart habit. No LazyVim/Omarchy mapping uses jj.
vim.keymap.set("i", "jj", "<Esc>", { desc = "Escape" })

return {}
