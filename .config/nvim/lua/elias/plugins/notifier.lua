return {
  "vigoux/notifier.nvim",
  priority = 50000,
  config = function()
    require("notifier").setup()
  end
}
