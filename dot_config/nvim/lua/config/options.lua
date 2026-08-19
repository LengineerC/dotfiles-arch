-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.spelllang = {}

if vim.g.neovide then
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_opacity = 0.93
  vim.g.neovide_normal_opacity = 0.93
  vim.g.neovide_position_animation_length = 0.2
  vim.g.neovide_cursor_vfx_mode = "railgun"
end
