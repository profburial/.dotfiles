local t = dofile("tests/support.lua")
return {
  launching_from_another_project_preserves_its_directory = function()
    local checkout = vim.fn.getcwd()
    local filename = t.file("other project/example.txt", { "external project" })
    local directory = vim.fs.dirname(filename)
    local probe = t.file("foreign-directory-probe.lua", {
      "assert(vim.fn.getcwd() == " .. string.format("%q", directory) .. ")",
      "assert(vim.fn.resolve(vim.fn.stdpath('config')) == " .. string.format("%q", checkout) .. ")",
      "assert(vim.api.nvim_buf_get_name(0) == " .. string.format("%q", filename) .. ")",
      "assert(vim.g.colors_name == 'terry')",
      'vim.cmd("qa!")',
    })
    local result = vim
      .system({
        checkout .. "/bin/tvim",
        "--headless",
        "-i",
        "NONE",
        "--cmd",
        "lua dofile(" .. string.format("%q", checkout .. "/tests/isolated.lua") .. ")",
        filename,
        "-c",
        "lua dofile(" .. string.format("%q", probe) .. ")",
      }, { cwd = directory, text = true })
      :wait(15000)
    t.equal(
      result.code,
      0,
      "Launching elsewhere loads TVIM without changing the project directory: " .. (result.stderr or "")
    )
  end,
  launching_tvim_preserves_the_default_profile = function()
    local filename = t.file("name with spaces.txt", { "trial contents" })
    local probe = t.file("profile-probe.lua", {
      "assert(vim.api.nvim_buf_get_name(0) == " .. string.format("%q", filename) .. ")",
      "for _, kind in ipairs({'data','cache','state'}) do assert(vim.fn.stdpath(kind):match('/tvim$')) end",
      'vim.cmd("qa!")',
    })
    local process = vim
      .system({
        "./bin/tvim",
        "--headless",
        "--cmd",
        'lua dofile("tests/isolated.lua")',
        "-i",
        "NONE",
        filename,
        "-c",
        "lua dofile(" .. string.format("%q", probe) .. ")",
      }, { text = true })
      :wait(15000)
    t.equal(process.code, 0, "The isolated profile opens filenames with spaces: " .. (process.stderr or ""))
    t.equal(
      vim.fn.readfile(vim.env.TVIM_TEST_ROOT .. "/config/nvim/init.lua"),
      { "default profile sentinel" },
      "Default profile remains unchanged"
    )
  end,
  tvim_starts_with_an_empty_editor = function()
    local probe = t.file("empty-probe.lua", {
      "assert(vim.api.nvim_buf_get_name(0) == '')",
      "assert(vim.bo.buftype == '')",
      "assert(#vim.api.nvim_list_wins() == 1)",
      "assert(vim.v.errmsg == '', vim.v.errmsg)",
      'vim.cmd("qa!")',
    })
    local result = vim
      .system({
        "./bin/tvim",
        "--headless",
        "--cmd",
        'lua dofile("tests/isolated.lua")',
        "-i",
        "NONE",
        "-c",
        "lua dofile(" .. string.format("%q", probe) .. ")",
      }, { text = true })
      :wait(15000)
    t.equal(result.code, 0, "Fresh startup is an empty editor: " .. (result.stderr or ""))
  end,
}
