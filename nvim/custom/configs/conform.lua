--type conform.options
local options = {
  lsp_fallback = true,

  formatters_by_ft = {
    lua = { "stylua" },

    typescript = { "prettier", "eslint_d" },
    typescriptreact = { "prettier", "eslint_d" },
    javascript = { "prettier", "eslint_d" },
    javascriptreact = { "prettier", "eslint_d" },
    css = { "prettier" },
    html = { "prettier" },

    sh = { "shfmt" },
  },

  -- adding same formatter for multiple filetypes can look too much work for some
  -- instead of the above code you could just use a loop! the config is just a table after all!

  format_on_save = function(bufnr)
    -- Disable autoformat on certain filetypes
    local ignore_filetypes = { "sql", "java" }
    if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
      return
    end
    -- Disable with a global or buffer-local variable
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    -- Disable autoformat for files in a certain path
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match("/node_modules/") then
      return
    end
    -- ...additional logic...
    return { async = true, timeout_ms = 500, lsp_fallback = true }
  end,
}

require("conform").setup(options)
