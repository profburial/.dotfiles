-- Load NvChad defaults (includes on_attach & capabilities)
local configs = require "nvchad.configs.lspconfig"
local on_attach = configs.on_attach
local capabilities = configs.capabilities

require("nvchad.configs.lspconfig").defaults()

-- Custom Ruby command
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
            filename = item.path,
          })
        end
      end

      vim.fn.setqflist(qf_list)
      vim.cmd "copen"
    end, bufnr)
  end, {
    nargs = "?",
    complete = function()
      return { "all" }
    end,
  })
end

vim.lsp.config("*", {
  on_attach = on_attach,
  capabilities = capabilities,
})

-- vim.lsp.config.standardrb = {
--   cmd = { "/Users/terry/.asdf/shims/standardrb", "--lsp" },
-- }

vim.lsp.config.ruby_lsp = {
  init_options = {
    formatter = "standardrb",
    linters = { "standardrb" },
    addonSettings = {
      ["Ruby LSP Rails"] = {
        enablePendingMigrationsPrompt = false,
      },
    },
  },
  on_attach = function(client, bufnr)
    add_ruby_deps_command(client, bufnr)
  end,
}

vim.lsp.config.lua_ls = {
  settings = { Lua = { diagnostics = { globals = { "vim" } } } },
}

-- Enable all servers
vim.lsp.enable {
  "ruby_lsp",
  "standardrb",
  "lua_ls",
  "html",
  "cssls",
  "eslint",
  "astro",
  "marksman",
  "intelephense",
  "gopls",
  "ruff",
  "pyright",
  "tailwindcss",
  "ts_ls",
  -- "csharp_ls",
  -- "bicep",
}
