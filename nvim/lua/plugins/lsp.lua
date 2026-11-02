---@type LazySpec[]
return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    lazy = false,
    opts = {
      ensure_installed = require("configs.languages").tools,
      auto_update = false,
      run_on_start = true,
      integrations = { ["mason-lspconfig"] = false, ["mason-null-ls"] = false, ["mason-nvim-dap"] = false },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "hrsh7th/cmp-nvim-lsp" },
    ---@return nil
    config = function()
      local group = vim.api.nvim_create_augroup("TvimLsp", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        ---@param event vim.api.keyset.create_autocmd.callback_args
        ---@return nil
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end
          local mappings = {
            gD = { vim.lsp.buf.declaration, "Declaration" },
            gd = { vim.lsp.buf.definition, "Definition" },
            ["<leader>D"] = { vim.lsp.buf.type_definition, "Type definition" },
            ["<leader>ra"] = { vim.lsp.buf.rename, "Rename" },
            ["<leader>wa"] = { vim.lsp.buf.add_workspace_folder, "Add workspace folder" },
            ["<leader>wr"] = { vim.lsp.buf.remove_workspace_folder, "Remove workspace folder" },
            ["<leader>wl"] = {
              function()
                vim.print(vim.lsp.buf.list_workspace_folders())
              end,
              "List workspace folders",
            },
            K = { vim.lsp.buf.hover, "Hover" },
          }
          for key, mapping in pairs(mappings) do
            vim.keymap.set("n", key, mapping[1], { buffer = event.buf, desc = "LSP " .. mapping[2] })
          end
          vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = event.buf, desc = "LSP signature help" })
          if client:supports_method("textDocument/documentColor") then
            vim.lsp.document_color.enable(true, { bufnr = event.buf })
          end
          if client.name == "ruby_lsp" then
            require("configs.ruby").attach(client, event.buf)
          end
        end,
      })
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
        ---@param client vim.lsp.Client
        ---@return nil
        on_init = function(client)
          client.server_capabilities.semanticTokensProvider = nil
        end,
      })
      local names = {}
      for name, options in pairs(require("configs.languages").servers) do
        vim.lsp.config(name, options)
        names[#names + 1] = name
      end
      vim.lsp.enable(names)
    end,
  },
}
