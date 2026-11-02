local M = {}

---Close a file buffer without losing unsaved text or window layout.
---@param bufnr? integer
---@return nil
function M.close_current(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end
  if vim.bo[bufnr].modified then
    vim.notify("Save this buffer with :write before closing it.", vim.log.levels.WARN)
    return
  end
  local replacement
  for _, candidate in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if candidate.bufnr ~= bufnr and vim.bo[candidate.bufnr].buftype == "" then
      replacement = candidate.bufnr
      break
    end
  end
  replacement = replacement or vim.api.nvim_create_buf(true, false)
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(window) == bufnr then
      vim.api.nvim_win_set_buf(window, replacement)
    end
  end
  vim.api.nvim_buf_delete(bufnr, { force = false })
end

return M
