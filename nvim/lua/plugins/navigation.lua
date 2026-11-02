---@type LazySpec[]
return {
  {
    "nvim-tree/nvim-web-devicons",
    opts = {
      strict = true,
      override_by_extension = { astro = { icon = "", color = "#EF8547", name = "astro" } },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
      { "<leader>e", "<cmd>NvimTreeFocus<CR>", desc = "Focus file tree" },
    },
    opts = {
      ---@param bufnr integer
      ---@return nil
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set("n", "/", api.live_filter.start, { buffer = bufnr, desc = "Filter file tree", nowait = true })
        vim.keymap.set(
          "n",
          "<Esc>",
          api.live_filter.clear,
          { buffer = bufnr, desc = "Clear tree filter", nowait = true }
        )
      end,
      live_filter = { prefix = "Filter: ", always_show_folders = true },
      filters = { dotfiles = false },
      disable_netrw = true,
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = { enable = true, update_root = false },
      view = { width = 30, preserve_window_proportions = true },
      renderer = {
        root_folder_label = false,
        highlight_git = "name",
        indent_markers = { enable = true },
        icons = {
          glyphs = {
            default = "󰈚",
            folder = { default = "", empty = "", empty_open = "", open = "", symlink = "" },
            git = { unmerged = "" },
          },
        },
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = { signs = { add = { text = "│" }, change = { text = "│" }, delete = { text = "󰍵" } } },
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>", desc = "Find all files" },
      { "<leader>fw", "<cmd>Telescope live_grep<CR>", desc = "Search text" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Find help" },
      { "<leader>ma", "<cmd>Telescope marks<CR>", desc = "Find marks" },
      { "<leader>fo", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search this buffer" },
    },
    ---@return { defaults: table<string, unknown> }
    opts = function()
      return {
        defaults = {
          prompt_prefix = "   ",
          selection_caret = " ",
          entry_prefix = " ",
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = { prompt_position = "top", preview_width = 0.55 },
            width = 0.87,
            height = 0.80,
          },
          mappings = { n = { q = require("telescope.actions").close } },
        },
      }
    end,
  },
}
