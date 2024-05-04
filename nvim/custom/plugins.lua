local plugins = {
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "html-lsp",
        "css-lsp",
        "astro-language-server",
        "bicep-lsp",
        "marksman",
        "pyright",
        "tailwindcss-language-server",
        "typescript-language-server",
        "eslint-lsp",
        "eslint-d",
        "prettier",
        "ruby-lsp",
        "solargraph",
        "gopls",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- defaults
        "vim",
        "lua",
        -- web dev
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "astro",
        -- custom
        "bash",
        "bicep",
        "python",
        "go",
        "prisma",
        "scss",
        "terraform",
        -- low level
        "c",
        "zig"
      },
    },
  },
  {
    "NvChad/nvim-colorizer.lua",
    enabled = false,
  },
  {
    "stevearc/conform.nvim",
    --  for users those who want auto-save conform + lazyloading!
    event = { "BufWritePre" },
    config = function()
      require "custom.configs.conform"
    end,
  },
}
return plugins
