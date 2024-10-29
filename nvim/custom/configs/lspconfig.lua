local configs = require("plugins.configs.lspconfig")
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"

local function add_ruby_deps_command(client, bufnr)
  vim.api.nvim_buf_create_user_command(bufnr, "ShowRubyDeps", function(opts)
      local params = vim.lsp.util.make_text_document_params()
      local showAll = opts.args == "all"

      client.request("rubyLsp/workspace/dependencies", params, function(error, result)
        if error then
          print("Error showing deps: " .. error)
          return
        end

        local qf_list = {}
        for _, item in ipairs(result) do
          if showAll or item.dependency then
            table.insert(qf_list, {
              text = string.format("%s (%s) - %s", item.name, item.version, item.dependency),
              filename = item.path
            })
          end
        end

        vim.fn.setqflist(qf_list)
        vim.cmd('copen')
      end, bufnr)
    end,
    { nargs = "?", complete = function() return { "all" } end })
end

lspconfig.ruby_ls.setup({
  init_options = {
    formatter = 'standard',
    linters = { 'standard' },
  },
  on_attach = function(client, buffer)
    add_ruby_deps_command(client, buffer)
  end,
  capabilities = capabilities,
})

lspconfig.standardrb.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.lua_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      }
    }
  }
})

lspconfig.html.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.astro.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.eslint.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.cssls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.bicep.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = {
    "dotnet",
    "/Users/terry/.local/share/nvim/mason/packages/bicep-lsp/extension/bicepLanguageServer/Bicep.LangServer.dll"
  }
})

lspconfig.marksman.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.intelephense.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.gopls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.csharp_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.ruff_lsp.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.pyright.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "python" }
})

lspconfig.tailwindcss.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.tsserver.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})
