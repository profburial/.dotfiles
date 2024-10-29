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
        "csharp-language-server@0.5.7",
        "ruff",
        "ruff-lsp",
        "pyright",
        "tailwindcss-language-server",
        "typescript-language-server",
        "eslint-lsp",
        "eslint_d",
        "prettier",
        "intelephense",
        "easy-coding-standard",
        "ruby-lsp",
        "standardrb",
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
        "php",
        -- custom
        "bash",
        "bicep",
        "c_sharp",
        "python",
        "go",
        "prisma",
        "scss",
        "terraform",
        "ruby",
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
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },
  {
    "nvim-web-devicons",
    opts = {
      strict = true,
      override_by_extension = {
        astro = {
          icon = "",
          color = "#EF8547",
          name = "astro",
        },
      },
    }
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
