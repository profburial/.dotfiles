---@param bufnr integer
---@return conform.FormatOpts
local function format_options(bufnr)
  local options = { bufnr = bufnr, timeout_ms = 500, lsp_format = "fallback" }
  if vim.bo[bufnr].filetype == "ruby" then
    local standard = vim.lsp.get_clients({ bufnr = bufnr, name = "standardrb", method = "textDocument/formatting" })
    if standard[1] then
      options.id = standard[1].id
    end
  end
  return options
end

---@type LazySpec[]
return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format(format_options(vim.api.nvim_get_current_buf()))
        end,
        mode = { "n", "x" },
        desc = "Format file or selection",
      },
    },
    opts = {
      formatters_by_ft = require("configs.languages").formatters_by_ft,
      default_format_opts = { lsp_format = "fallback", timeout_ms = 500 },
      format_on_save = format_options,
      notify_on_error = true,
      notify_no_formatters = true,
    },
  },
}
