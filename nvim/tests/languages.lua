local t = dofile("tests/support.lua")
local examples = {}

for extension, filetype in pairs({ astro = "astro", bicep = "bicep", jbuilder = "ruby" }) do
  examples["custom_extension_activates_" .. filetype] = function()
    vim.cmd.edit(t.file("filetypes/example." .. extension, { "" }))
    t.equal(vim.bo.filetype, filetype, "Opening ." .. extension .. " selects " .. filetype)
  end
end

---@param mode string
---@return fun(): nil
local function formatters(mode)
  local old_path = vim.env.PATH
  local old_mode = vim.env.TVIM_FORMATTER_MODE
  local directory = vim.env.TVIM_TEST_ROOT .. "/executables"
  vim.fn.mkdir(directory, "p")
  local script = {
    "#!/usr/bin/env python3",
    "import os, sys, time",
    "name = os.path.basename(sys.argv[0])",
    'if "--version" in sys.argv: print("1.0.0"); sys.exit(0)',
    'mode = os.environ.get("TVIM_FORMATTER_MODE", "ok")',
    'if mode == "slow": time.sleep(3)',
    'if mode == "fail": print("fixture formatter failed", file=sys.stderr); sys.exit(1)',
    "text = sys.stdin.read()",
    'if name == "prettier": text = text.replace("raw", "prettier")',
    'elif name == "eslint_d": text = text.replace("prettier", "chained")',
    'elif name == "ruff":',
    '    assert "--fix" in sys.argv, "Ruff must fix lint errors"',
    '    text = text.replace("import unused\\n", "")',
    'else: text = text.replace("raw", "formatted")',
    "sys.stdout.write(text)",
  }
  for _, name in ipairs({ "prettier", "eslint_d", "ruff", "stylua", "shfmt" }) do
    local path = directory .. "/" .. name
    vim.fn.writefile(script, path)
    assert(vim.uv.fs_chmod(path, 493))
  end
  vim.env.PATH = directory .. ":" .. old_path
  vim.env.TVIM_FORMATTER_MODE = mode
  return function()
    vim.env.PATH = old_path
    vim.env.TVIM_FORMATTER_MODE = old_mode
  end
end

for _, extension in ipairs({ "js", "jsx", "ts", "tsx", "lua", "css", "html", "sh", "py" }) do
  examples["saving_applies_formatter_chain_" .. extension] = function()
    local restore = formatters("ok")
    local python = extension == "py"
    local filename = t.file("formatting/sample." .. extension, python and { "import unused", "print(1)" } or { "raw" })
    local ok, err = pcall(function()
      vim.cmd.edit(filename)
      vim.cmd.write()
      local expected = ({
        js = "chained",
        jsx = "chained",
        ts = "chained",
        tsx = "chained",
        css = "prettier",
        html = "prettier",
      })[extension] or "formatted"
      t.equal(
        vim.fn.readfile(filename),
        python and { "print(1)" } or { expected },
        "Save applies the intended formatter chain for " .. extension
      )
    end)
    restore()
    assert(ok, err)
  end
end

for _, mode in ipairs({ "fail", "slow", "missing" }) do
  examples["formatter_failure_preserves_save_" .. mode] = function()
    local restore = formatters(mode)
    if mode == "missing" then
      vim.fn.delete(vim.env.TVIM_TEST_ROOT .. "/executables/stylua")
      -- Remove Mason and user bins so a real formatter cannot hide this case.
      vim.env.PATH = vim.env.TVIM_TEST_ROOT .. "/executables:/usr/bin:/bin"
    end
    local filename = t.file("failures/" .. mode .. ".lua", { "original" })
    local notified = #_G.tvim_test_messages
    local ok, err = pcall(function()
      vim.cmd.edit(filename)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "raw" })
      local start = vim.uv.hrtime()
      vim.cmd.write()
      assert((vim.uv.hrtime() - start) / 1e9 < 5, "Formatter failure must leave writes bounded")
      t.equal(vim.fn.readfile(filename), { "raw" }, "Formatter failure preserves the saved edits")
      t.wait(function()
        return #_G.tvim_test_messages > notified
      end, "Formatter failure surfaces a notification")
    end)
    restore()
    assert(ok, err)
  end
end

examples.missing_tools_do_not_prevent_editing = function()
  local add = vim.treesitter.language.add
  vim.treesitter.language.add = function(language, ...)
    if language == "zig" then
      error("external parser unavailable")
    end
    return add(language, ...)
  end
  local notified = #_G.tvim_test_messages
  local ok, err = pcall(function()
    local filename = t.file("missing/parser.zig", { "param name string" })
    vim.cmd.edit(filename)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "param edited string" })
    vim.api.nvim_exec_autocmds("FileType", { buffer = 0 })
    vim.api.nvim_exec_autocmds("FileType", { buffer = 0 })
    t.equal(
      vim.api.nvim_buf_get_lines(0, 0, -1, false),
      { "param edited string" },
      "Missing parser leaves the buffer editable"
    )
    local warnings = 0
    for index = notified + 1, #_G.tvim_test_messages do
      if _G.tvim_test_messages[index].text:match("Parser unavailable for zig") then
        warnings = warnings + 1
      end
    end
    assert(warnings == 1, "Missing parser does not repeat warnings")
  end)
  vim.treesitter.language.add = add
  assert(ok, err)
end

examples.ruby_save_prefers_standardrb = function()
  local filename = t.file("formatting/preference.rb", { "raw" })
  vim.cmd.edit(filename)
  t.lsp("format_ruby")
  t.lsp("format_standard", "standardrb")
  vim.cmd.write()
  t.equal(
    vim.fn.readfile(filename),
    { "standard" },
    "Ruby save uses StandardRB once when both servers support formatting"
  )
end

return examples
