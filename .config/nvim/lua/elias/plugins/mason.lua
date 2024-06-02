local packages = {
  -- LSP
  "rust-analyzer",
  "lua-language-server",
  "typescript-language-server",

  -- Formatters
  "stylua",
  "biome"
}

return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➔",
            package_uninstalled = "✗"
          }
        },

        ensure_installed = packages
      })
    end
  }
}
