return {
  {
    -- Availiable Themes:
    -- onedark
    -- onelight
    -- onedark_vivid
    -- onedark_dark
    -- vaporwave
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    config = function()
      require("onedarkpro").setup({
        options = {
          cursorline = false,
          transparency = false,
          terminal_colors = true,
        },
      })
    end,
  },
  {
    -- catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      transparent_background = false,
    },
  },
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require("github-theme").setup({
        options = {
          transparent = false,
        },
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-macchiato",
    },
  },
}
