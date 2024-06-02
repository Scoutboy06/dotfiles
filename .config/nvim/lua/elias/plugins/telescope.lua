return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.6",
  branch = "0.1.x",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("telescope").setup({
      pickers = {
        colorscheme = {
          enable_preview = true
        }
      }
    })
  end
}
