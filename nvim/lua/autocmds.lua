local group = vim.api.nvim_create_augroup("TvimEditor", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "ruby",
  ---@return nil
  callback = function()
    -- Ruby's default dot trigger reindents unfinished method calls while typing.
    vim.opt_local.indentkeys:remove(".")
  end,
})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})
