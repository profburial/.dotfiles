local configs = require("plugins.configs.lspconfig")
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"

lspconfig.lua_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
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

lspconfig.marksman.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.ruby_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

-- lspconfig.solargraph.setup({
--   on_attach = on_attach,
--   capabilities = capabilities,
--   cmd = { os.getenv("HOME") .. "/.asdf/shims/solargraph", 'stdio' },
--   root_dir = lspconfig.util.root_pattern("Gemfile", ".git", "."),
--   settings = {
--     solargraph = {
--       autoformat = true,
--       completion = true,
--       diagnostic = true,
--       folding = true,
--       references = true,
--       rename = true,
--       symbols = true
--     }
--   }
-- })

lspconfig.gopls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.pyright.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.tailwindcss.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.tsserver.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})
