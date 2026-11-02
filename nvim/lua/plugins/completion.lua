---@type LazySpec[]
return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lua",
      "FelipeLema/cmp-async-path",
      { "windwp/nvim-autopairs", opts = {} },
    },
    ---@return nil
    config = function()
      local cmp = require("cmp")
      local icons = {
        Namespace = "󰌗",
        Text = "󰉿",
        Method = "󰆧",
        Function = "󰆧",
        Constructor = "",
        Field = "󰜢",
        Variable = "󰀫",
        Class = "󰠱",
        Interface = "",
        Module = "",
        Property = "󰜢",
        Unit = "󰑭",
        Value = "󰎠",
        Enum = "",
        Keyword = "󰌋",
        Snippet = "",
        Color = "󱓻",
        File = "󰈚",
        Reference = "󰈇",
        Folder = "󰉋",
        EnumMember = "",
        Constant = "󰏿",
        Struct = "󰙅",
        Event = "",
        Operator = "󰆕",
        TypeParameter = "󰊄",
      }

      ---@param text string
      ---@param max_width integer
      ---@return string
      local function truncate(text, max_width)
        if #text > max_width then
          return text:sub(1, max_width) .. "…"
        end
        return text
      end

      cmp.setup({
        completion = { completeopt = "menu,menuone" },
        snippet = {
          ---@param args { body: string }
          ---@return nil
          expand = function(args)
            vim.snippet.expand(args.body)
          end,
        },
        window = {
          completion = {
            border = "single",
            scrollbar = false,
            side_padding = 1,
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
          },
          documentation = { border = "single" },
        },
        formatting = {
          fields = { "abbr", "kind", "menu" },
          ---@param _ cmp.Entry
          ---@param item vim.CompletedItem
          ---@return vim.CompletedItem
          format = function(_, item)
            item.kind = " " .. (icons[item.kind] or "") .. " " .. item.kind
            item.menu_hl_group = "Comment"
            -- Bound both columns so the popup leaves room for the documentation float beside it.
            item.abbr = truncate(item.abbr, 40)
            item.menu = truncate(item.menu or "", 30)
            return item
          end,
        },
        mapping = {
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i" }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "nvim_lua" },
          { name = "async_path" },
        },
      })
      cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
    end,
  },
}
