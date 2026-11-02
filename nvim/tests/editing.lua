local t = dofile("tests/support.lua")

return {
  ruby_newlines_keep_block_indentation = function()
    t.editor(function(call, keys)
      call("nvim_command", "edit " .. vim.fn.fnameescape(t.file("ruby-newline.rb", { "def example", "end" })))
      call("nvim_win_set_cursor", 0, { 1, 0 })
      keys("A<CR>object")
      t.equal(call("nvim_get_current_line"), "  object", "Ruby newlines still indent the method body")
    end)
  end,
  typing_a_ruby_period_preserves_indentation = function()
    t.editor(function(call, keys)
      call("nvim_command", "edit " .. vim.fn.fnameescape(t.file("period.rb", { "def example", "    object", "end" })))
      call("nvim_win_set_cursor", 0, { 2, 9 })
      keys("A.")
      t.equal(
        call("nvim_get_current_line"),
        "    object.",
        "Typing a Ruby method-access dot preserves the existing indentation"
      )
    end)
  end,
  autocomplete_works_without_a_snippet_collection = function()
    t.editor(function(call, keys)
      call("nvim_command", "edit " .. vim.fn.fnameescape(t.file("completion.lua", { "" })))
      call("nvim_exec_lua", "dofile('tests/support.lua').lsp('ok')", {})
      keys("itvim")
      keys("<C-Space>")
      t.wait(function()
        return call("nvim_exec_lua", "return require('cmp').visible()", {})
      end, "LSP completion opens the popup")
      keys("<C-n><CR>")
      t.wait(function()
        return call("nvim_get_current_line") == "tvim_call(value)"
      end, "Confirm expands native LSP placeholders")
      keys("<Esc>A(")
      t.equal(call("nvim_get_current_line"), "tvim_call(value)()", "Typing an opening delimiter inserts its pair")
      keys("<Esc>")
      call("nvim_exec_lua", "if vim.snippet.active() then vim.snippet.stop() end", {})
      call("nvim_command", "enew!")
      keys("i<Tab><Esc>")
      t.equal(call("nvim_get_current_line"), "  ", "Tab outside the menu follows two-space indentation")
    end)
  end,
  retained_insert_escape_changes_mode = function()
    t.editor(function(call, keys)
      keys("ihello jk")
      t.equal(call("nvim_get_mode").mode, "n", "jk leaves insert mode")
      t.equal(call("nvim_get_current_line"), "hello ", "jk does not insert escape keys into text")
    end)
  end,
  semicolon_enters_command_mode = function()
    t.editor(function(call, keys)
      keys(";")
      t.equal(call("nvim_get_mode").mode, "c", "Semicolon opens command mode")
    end)
  end,
  native_comment_shortcut_toggles_source = function()
    t.editor(function(call, keys)
      call("nvim_command", "edit " .. vim.fn.fnameescape(t.file("comment.lua", { "local value = 1" })))
      keys(" /")
      t.equal(call("nvim_get_current_line"), "-- local value = 1", "Comment shortcut comments Lua source")
      keys(" /")
      t.equal(call("nvim_get_current_line"), "local value = 1", "Comment shortcut restores Lua source")
    end)
  end,
  lsp_definition_shortcut_opens_destination = function()
    t.editor(function(call, keys)
      local destination = t.file("destination.lua", { "-- destination", "value = 1" })
      call("nvim_command", "edit " .. vim.fn.fnameescape(t.file("navigation.lua", { "old" })))
      call("nvim_exec_lua", "dofile('tests/support.lua').lsp('ok')", {})
      keys("gd")
      t.wait(function()
        return call("nvim_buf_get_name", 0) == destination
      end, "Definition mapping opens the external LSP destination")
      t.equal(call("nvim_win_get_cursor", 0)[1], 2, "Definition mapping selects the target line")
    end)
  end,
  lsp_rename_shortcut_updates_text = function()
    t.editor(function(call, keys)
      call("nvim_command", "edit " .. vim.fn.fnameescape(t.file("rename.lua", { "old" })))
      call("nvim_exec_lua", "dofile('tests/support.lua').lsp('ok')", {})
      keys(" ra")
      keys("<C-u>renamed<CR>")
      t.wait(function()
        return call("nvim_get_current_line") == "renamed"
      end, "Rename mapping applies the LSP workspace edit")
    end)
  end,
}
