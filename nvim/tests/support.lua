local M = {}

---Assert an observable result with a descriptive failure.
---@param actual unknown
---@param expected unknown
---@param behavior string
---@return nil
function M.equal(actual, expected, behavior)
  assert(
    vim.deep_equal(actual, expected),
    behavior .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
  )
end

---Wait for an observable editor condition.
---@param condition fun(): boolean
---@param behavior string
---@return nil
function M.wait(condition, behavior)
  assert(vim.wait(5000, condition, 10), behavior)
end

---Send user input through the editor's mappings.
---@param input string
---@return nil
function M.keys(input)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(input, true, false, true), "xt", false)
end

---Create an isolated fixture file.
---@param name string
---@param lines string[]
---@return string
function M.file(name, lines)
  local path = vim.env.TVIM_TEST_ROOT .. "/fixtures/" .. name
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
  return path
end

---Reset visible buffers between behavioral examples.
---@return nil
function M.reset()
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop(true)
  end
  M.keys("<Esc>")
  pcall(vim.cmd, "NvimTreeClose")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  vim.cmd.enew()
end

---Attach the external protocol fixture to the current buffer.
---@param mode string
---@param name? string
---@return vim.lsp.Client
function M.lsp(mode, name)
  local root = vim.env.TVIM_TEST_ROOT .. "/fixtures"
  local id = assert(vim.lsp.start({
    name = name or "ruby_lsp",
    cmd = { "python3", vim.fn.getcwd() .. "/tests/lsp_server.py", mode, root },
    root_dir = root,
  }))
  local client = assert(vim.lsp.get_client_by_id(id))
  M.wait(function()
    return client.initialized and vim.lsp.buf_is_attached(0, id)
  end, "External test language server attaches")
  return client
end

---Drive a fresh editor through its RPC input surface.
---@param example fun(call: fun(method: string, ...): unknown, keys: fun(input: string): nil): nil
---@return nil
function M.editor(example)
  local job = vim.fn.jobstart(
    { "./bin/tvim", "--embed", "--headless", "-i", "NONE", "--cmd", 'lua dofile("tests/isolated.lua")' },
    { rpc = true }
  )
  assert(job > 0, "Child editor starts")
  ---@param method string
  ---@param ... unknown
  ---@return unknown
  local function call(method, ...)
    return vim.rpcrequest(job, method, ...)
  end
  ---@param input string
  ---@return nil
  local function keys(input)
    call("nvim_input", input)
    vim.wait(100, function()
      return false
    end)
  end
  local ok, err = xpcall(function()
    call("nvim_ui_attach", 100, 30, { rgb = true })
    example(call, keys)
  end, debug.traceback)
  pcall(call, "nvim_command", "qa!")
  vim.fn.jobstop(job)
  assert(ok, err)
end

return M
