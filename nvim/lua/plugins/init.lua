return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
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
        "zig",
      },
    },
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
    },
  },
  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },
}
