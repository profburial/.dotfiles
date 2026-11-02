---@type LazySpec[]
return {
  {
    "akinsho/bufferline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<Tab>", "<cmd>BufferLineCycleNext<CR>", desc = "Next file buffer" },
      { "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous file buffer" },
      {
        "<leader>x",
        function()
          require("configs.buffers").close_current()
        end,
        desc = "Close file buffer",
      },
    },
    opts = {
      ---@param defaults bufferline.Config
      ---@return bufferline.Highlights
      highlights = function(defaults)
        for name, highlight in pairs(defaults.highlights) do
          local group = "BufferLineBackground"
          if name:match("_selected$") then
            group = "BufferLineBufferSelected"
          elseif name:match("_visible$") then
            group = "BufferLineBufferVisible"
          end
          -- Icons also read these values; setting highlight groups alone leaves seams.
          highlight.bg = { highlight = group, attribute = "bg" }
          local component = name:gsub("_selected$", ""):gsub("_visible$", "")
          if
            vim.tbl_contains(
              { "background", "buffer", "close_button", "numbers", "duplicate", "diagnostic" },
              component
            )
          then
            highlight.fg = { highlight = group, attribute = "fg" }
          elseif component == "separator" or component == "tab_separator" then
            highlight.fg = { highlight = "BufferLineFill", attribute = "bg" }
          end
        end
        return defaults.highlights
      end,
      options = {
        always_show_bufferline = false,
        show_tab_indicators = true,
        modified_icon = "",
        ---@param bufnr integer
        ---@return nil
        close_command = function(bufnr)
          require("configs.buffers").close_current(bufnr)
        end,
        ---@param bufnr integer
        ---@return nil
        right_mouse_command = function(bufnr)
          require("configs.buffers").close_current(bufnr)
        end,
        ---@param bufnr integer
        ---@return boolean
        custom_filter = function(bufnr)
          return vim.bo[bufnr].buftype == ""
        end,
        offsets = { { filetype = "NvimTree", text = "File Explorer", text_align = "left" } },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        globalstatus = true,
        component_separators = "",
        section_separators = "",
        theme = {
          normal = {
            a = { fg = "#2b3e50", bg = "#89B4FA", gui = "bold" },
            b = { fg = "#ffffff", bg = "#2f2e3e" },
            c = { fg = "#bfc5cb", bg = "#232232" },
          },
          insert = { a = { fg = "#2b3e50", bg = "#ABE9B3", gui = "bold" } },
          visual = { a = { fg = "#2b3e50", bg = "#d0a9e5", gui = "bold" } },
          replace = { a = { fg = "#2b3e50", bg = "#de4242", gui = "bold" } },
          command = { a = { fg = "#2b3e50", bg = "#e6db74", gui = "bold" } },
          inactive = {
            a = { fg = "#bfc5cb", bg = "#232232" },
            b = { fg = "#bfc5cb", bg = "#232232" },
            c = { fg = "#bfc5cb", bg = "#232232" },
          },
        },
      },
      sections = {
        lualine_a = { { "mode", icon = "" } },
        lualine_b = { { "filename", symbols = { modified = " ", readonly = " ", unnamed = "Empty" } } },
        lualine_c = { "branch", "diff", "diagnostics" },
        lualine_x = {
          function()
            return vim.lsp.status()
          end,
          function()
            local names = {}
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
              names[#names + 1] = client.name
            end
            table.sort(names)
            return table.concat(names, ", ")
          end,
        },
        lualine_y = {
          {
            function()
              return "󰉋 " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            end,
            cond = function()
              return vim.o.columns > 85
            end,
          },
        },
        lualine_z = {
          {
            function()
              return vim.fn.line(".") .. "/" .. vim.fn.virtcol(".")
            end,
            icon = "",
          },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>ch", "<cmd>WhichKey<CR>", desc = "Shortcut cheatsheet" },
      { "<leader>wK", "<cmd>WhichKey<CR>", desc = "All shortcuts" },
      {
        "<leader>wk",
        function()
          require("which-key").show({ keys = vim.fn.input("WhichKey: ") })
        end,
        desc = "Query shortcuts",
      },
    },
    opts = { spec = { { "<leader>f", group = "Find" }, { "<leader>w", group = "Workspace" } } },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = { indent = { char = "│", highlight = "IblIndent" }, scope = { enabled = true, highlight = "IblScope" } },
  },
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    opts = { user_default_options = { names = false, css = true, tailwind = true } },
  },
}
