-- Tool installation is provisioned separately from offline behavior checks.
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    require("mason-tool-installer").setup({ run_on_start = false })
  end,
})
