local plugins = {
  {
    "nvimtools/none-ls.nvim",
    event = "VeryLazy",
    opts = function()
      return require "custom.configs.null-ls"
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },

  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup {
        ensure_installed = {
          "lua-language-server",
          "stylua",
          "html-lsp",
          "css-lsp",
          "prettierd",
          "typescript-language-server",
          "rust-analyzer",
          "tailwindcss-language-server",
          "eslint-lsp",
        },
      }
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
      },
    },
  },

  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup {
        ft = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "css",
          "html",
        },
        opts = {
          enable_close_on_slash = true,
        },
      }
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
      opts = require "plugins.configs.treesitter"

      opts.ensure_installed = {
        "lua",
        "javascript",
        "typescript",
        "jsx",
        "css",
        "rust",
      }
    end,
  },
}

return plugins
