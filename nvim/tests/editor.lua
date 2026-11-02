local t = dofile("tests/support.lua")
local examples = {}

for _, shortcut in ipairs({ "<C-n>", "<leader>e" }) do
  examples["tree_shortcut_focuses_navigation_" .. shortcut] = function()
    t.keys(shortcut:gsub("<leader>", " "))
    t.equal(vim.bo.filetype, "NvimTree", "Tree shortcut focuses the file sidebar")
  end
end
for _, search in ipairs({ { " ff", "needle.txt", "find" }, { " fw", "unique_tvim_text", "grep" } }) do
  examples["familiar_search_selects_file_" .. search[3]] = function()
    local filename = t.file("search/needle.txt", { "first", "unique_tvim_text" })
    t.editor(function(call, keys)
      call("nvim_command", "cd " .. vim.fn.fnameescape(vim.fs.dirname(filename)))
      keys(search[1])
      t.wait(function()
        return call("nvim_get_option_value", "filetype", { buf = 0 }) == "TelescopePrompt"
      end, "Search opens a picker")
      keys(search[2])
      vim.wait(300, function()
        return false
      end)
      keys("<CR>")
      t.wait(function()
        return call("nvim_buf_get_name", 0) == filename
      end, "Picker selection opens the known file")
      if search[3] == "grep" then
        t.equal(call("nvim_win_get_cursor", 0)[1], 2, "Text search selects the matching line")
      end
    end)
  end
end

examples.reapplying_terry_preserves_user_colors = function()
  require("lazy").load({
    plugins = { "nvim-tree.lua", "telescope.nvim", "bufferline.nvim", "lualine.nvim", "nvim-cmp" },
  })
  vim.cmd.colorscheme("terry")
  vim.cmd.colorscheme("terry")
  for name, expected in pairs({
    Normal = { fg = "#ffffff", bg = "#263645" },
    NvimTreeNormal = { fg = "#ffffff", bg = "#2b3e50" },
    ["@variable"] = { fg = "#eaecee" },
    ["@property"] = { fg = "#ffffff" },
    ["@variable.builtin"] = { fg = "#e6db74" },
    TelescopePromptNormal = { bg = "#243443" },
    CmpItemAbbrMatch = { fg = "#89B4FA" },
    GitSignsAdd = { fg = "#ABE9B3" },
    WhichKey = { fg = "#89B4FA" },
  }) do
    local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
    for attribute, color in pairs(expected) do
      t.equal(actual[attribute], tonumber(color:sub(2), 16), name .. " preserves " .. attribute)
    end
  end
end

examples.dim_file_icons_read_against_the_tree_background = function()
  require("lazy").load({ plugins = { "nvim-web-devicons", "nvim-tree.lua" } })
  vim.cmd.colorscheme("terry")
  local devicons = require("nvim-web-devicons")
  local contrast = require("themes.contrast")
  local tree_background = vim.api.nvim_get_hl(0, { name = "NvimTreeNormal", link = false }).bg
  local background = string.format("#%06x", tree_background)
  for _, filename in ipairs({ "package.json", "tsconfig.json" }) do
    local icon, highlight = devicons.get_icon(filename, nil, { strict = true })
    local _, color = devicons.get_icon_color(filename, nil, { strict = true })
    assert(icon and highlight, filename .. " has a file icon")
    assert(
      contrast.ratio(color, background) >= 4.5,
      filename .. " icon " .. color .. " reads against the tree background " .. background
    )
    local applied = vim.api.nvim_get_hl(0, { name = highlight, link = false }).fg
    t.equal(applied, tonumber(color:sub(2), 16), filename .. " icon highlight uses the readable color")
  end
  local fallback = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "DevIconDefault", link = false }).fg)
  assert(
    contrast.ratio(fallback, background) >= 4.5,
    "Files without a known type get an icon that reads against the tree background: " .. fallback
  )
  local _, astro = devicons.get_icon_color("site.astro", "astro")
  assert(contrast.ratio(astro, background) >= 4.5, "The custom Astro icon reads against the tree background")
  local _, markdown = devicons.get_icon_color("notes.md", "md")
  t.equal(markdown:lower(), "#dddddd", "Icons that already read keep their color")
end

examples.buffer_navigation_preserves_unsaved_work = function()
  local first = t.file("buffers/first.txt", { "saved" })
  local second = t.file("buffers/second.txt", { "other" })
  t.editor(function(call, keys)
    call("nvim_command", "edit " .. vim.fn.fnameescape(first))
    local first_buffer = call("nvim_get_current_buf")
    call("nvim_command", "vsplit " .. vim.fn.fnameescape(second))
    local second_buffer = call("nvim_get_current_buf")
    keys(" e")
    local tree = call("nvim_get_current_win")
    call("nvim_command", "wincmd p")
    keys("<Tab>")
    t.equal(call("nvim_get_current_buf"), first_buffer, "Tab cycles listed files, skipping the sidebar")
    keys("<S-Tab>")
    t.equal(call("nvim_get_current_buf"), second_buffer, "Shift-Tab cycles backward through files")
    local windows = call("nvim_list_wins")
    keys(" x")
    t.equal(call("nvim_buf_is_valid", second_buffer), false, "Closing a clean file deletes that file buffer")
    t.equal(call("nvim_list_wins"), windows, "Closing a clean file preserves the layout")
    t.equal(call("nvim_win_is_valid", tree), true, "Closing a file preserves the tree")
    call("nvim_buf_set_lines", first_buffer, 0, -1, false, { "unsaved text" })
    keys(" x")
    t.equal(call("nvim_get_current_buf"), first_buffer, "Dirty close keeps the exact active buffer")
    t.equal(call("nvim_buf_get_lines", first_buffer, 0, -1, false), { "unsaved text" }, "Dirty close preserves edits")
    local messages = call("nvim_exec2", "messages", { output = true }).output
    assert(messages:match(":write"), "Dirty close warns how to save")
  end)
end

examples.buffer_bar_components_preserve_state_backgrounds = function()
  require("bufferline")
  vim.cmd.colorscheme("terry")
  vim.cmd.colorscheme("terry")
  vim.cmd.redrawtabline()
  for suffix, background in pairs({ [""] = "#2b3e50", Visible = "#243443", Selected = "#263645" }) do
    for _, component in ipairs({ "CloseButton", "Modified", "Separator", "Numbers", "Diagnostic", "Duplicate" }) do
      local name = "BufferLine" .. component .. suffix
      local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
      t.equal(actual.bg, tonumber(background:sub(2), 16), name .. " shares its buffer's Terry background")
    end
  end
end

examples.tree_filter_hides_nonmatching_files = function()
  local filename = t.file("tree-filter/needle.txt", { "match" })
  t.file("tree-filter/other.txt", { "other" })
  t.editor(function(call, keys)
    call("nvim_command", "cd " .. vim.fn.fnameescape(vim.fs.dirname(filename)))
    keys(" e")
    local tree = call("nvim_get_current_buf")
    keys("/")
    keys("needle")
    keys("<CR>")
    local lines = table.concat(call("nvim_buf_get_lines", tree, 0, -1, false), "\n")
    assert(lines:find("needle.txt", 1, true), "Live filtering keeps matching files visible")
    assert(not lines:find("other.txt", 1, true), "Live filtering hides nonmatching files")
    assert(lines:find("Filter: /needle/", 1, true), "Tree shows its active filter")
    keys("<Esc>")
    lines = table.concat(call("nvim_buf_get_lines", tree, 0, -1, false), "\n")
    assert(lines:find("other.txt", 1, true), "Escape restores files hidden by the tree filter")
  end)
end

examples.source_buffers_keep_normal_search = function()
  t.editor(function(call, keys)
    call("nvim_command", "edit " .. vim.fn.fnameescape(t.file("search-shortcut.txt", { "first", "needle" })))
    keys("/")
    t.equal(call("nvim_eval", "getcmdtype()"), "/", "Slash keeps native search in source buffers")
    keys("needle<CR>")
    t.equal(call("nvim_win_get_cursor", 0)[1], 2, "Native search selects the matching source line")
  end)
end

return examples
