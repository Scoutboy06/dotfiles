-- Custom plugins go here
-- This file is automatically loaded by lazy.nvim

return {
  -- Customize colorscheme
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      transparent = false,
    },
  },

  -- Configure LazyVim to use tokyonight
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },

  -- Add more custom plugins here
  -- Example:
  -- { "github/copilot.vim" },
}
