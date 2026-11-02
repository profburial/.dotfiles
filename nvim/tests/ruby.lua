local t = dofile("tests/support.lua")
local examples = {}

for _, all in ipairs({ false, true }) do
  examples["ruby_dependency_browsing_produces_navigable_results_" .. tostring(all)] = function()
    vim.cmd.edit(t.file("workspace.rb", { "puts :example" }))
    local direct = t.file("direct.rb", { "# direct dependency" })
    local transitive = t.file("transitive.rb", { "# transitive dependency" })
    local client = t.lsp("ok")
    local buffer = vim.api.nvim_get_current_buf()
    vim.lsp.buf_detach_client(buffer, client.id)
    assert(vim.lsp.buf_attach_client(buffer, client.id))
    t.wait(function()
      return vim.fn.exists(":ShowRubyDeps") == 2
    end, "Ruby command remains available after reattachment")
    vim.cmd("ShowRubyDeps" .. (all and " all" or ""))
    t.wait(function()
      return vim.bo.filetype == "qf"
    end, "Dependency command opens quickfix")
    local actual = {}
    for _, item in ipairs(vim.fn.getqflist()) do
      actual[#actual + 1] = { path = vim.api.nvim_buf_get_name(item.bufnr), text = item.text }
    end
    local expected = { { path = direct, text = "direct (1.2.3) - true" } }
    if all then
      expected[#expected + 1] = { path = transitive, text = "transitive (4.5.6) - false" }
    end
    t.equal(actual, expected, "Quickfix preserves exact dependency names, versions, flags and paths")
  end
end
for _, mode in ipairs({ "error", "malformed", "missing" }) do
  examples["ruby_dependency_failure_preserves_quickfix_" .. mode] = function()
    vim.cmd.edit(t.file(mode .. ".rb", { "puts :example" }))
    t.lsp(mode)
    vim.fn.setqflist({ { text = "keep prior results", filename = t.file("prior.rb", { "" }), lnum = 1 } })
    local before = vim.fn.getqflist()
    local notified = #_G.tvim_test_messages
    vim.cmd.ShowRubyDeps()
    t.wait(function()
      return #_G.tvim_test_messages > notified
    end, "Invalid dependency response is surfaced")
    t.equal(vim.fn.getqflist(), before, "Failed dependency request preserves prior quickfix results")
  end
end
examples.closed_ruby_buffer_ignores_dependency_reply = function()
  vim.cmd.edit(t.file("closed.rb", { "puts :example" }))
  t.lsp("delayed")
  vim.fn.setqflist({ { text = "prior result", lnum = 1 } })
  local before = vim.fn.getqflist()
  vim.cmd.ShowRubyDeps()
  vim.cmd("bwipeout!")
  vim.wait(400, function()
    return false
  end)
  t.equal(vim.fn.getqflist(), before, "Reply after buffer closure leaves quickfix untouched")
end
return examples
