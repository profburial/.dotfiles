local M = {}

---Expose Ruby dependency browsing in an attached Ruby buffer.
---@param client vim.lsp.Client
---@param bufnr integer
---@return nil
function M.attach(client, bufnr)
  if client.name ~= "ruby_lsp" or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_create_user_command(bufnr, "ShowRubyDeps", function(options)
    if options.args ~= "" and options.args ~= "all" then
      vim.notify("Use :ShowRubyDeps or :ShowRubyDeps all", vim.log.levels.WARN)
      return
    end
    local accepted = client:request("rubyLsp/workspace/dependencies", {
      textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    }, function(err, result)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      if err then
        vim.notify("Ruby dependencies: " .. (err.message or vim.inspect(err)), vim.log.levels.ERROR)
        return
      end
      if type(result) ~= "table" or not vim.islist(result) then
        vim.notify("Ruby dependencies: invalid response; retry after restarting ruby_lsp.", vim.log.levels.ERROR)
        return
      end
      local entries = {}
      for _, item in ipairs(result) do
        if
          type(item) ~= "table"
          or type(item.name) ~= "string"
          or type(item.version) ~= "string"
          or type(item.path) ~= "string"
          or item.path == ""
          or type(item.dependency) ~= "boolean"
        then
          vim.notify("Ruby dependencies: invalid entry; retry after restarting ruby_lsp.", vim.log.levels.ERROR)
          return
        end
        if options.args == "all" or item.dependency then
          entries[#entries + 1] = {
            text = string.format("%s (%s) - %s", item.name, item.version, tostring(item.dependency)),
            filename = item.path,
            lnum = 1,
          }
        end
      end
      vim.fn.setqflist({}, " ", { title = "Ruby dependencies", items = entries })
      vim.cmd.copen()
    end, bufnr)
    if not accepted then
      vim.notify("Ruby dependencies: request rejected; check :LspInfo and restart ruby_lsp.", vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    force = true,
    desc = "Show Ruby workspace dependencies",
    complete = function()
      return { "all" }
    end,
  })
end

return M
