local support = dofile("tests/support.lua")
local failures = {}
local messages = {}
local notify = vim.notify
vim.notify = function(message, level, options)
  messages[#messages + 1] = { text = tostring(message), level = level }
  notify(message, level, options)
end
_G.tvim_test_messages = messages
vim.wait(100, function()
  return false
end)
if vim.v.errmsg ~= "" then
  failures[#failures + 1] = "startup: " .. vim.v.errmsg
end
for _, suite in ipairs({ "profile", "editor", "languages", "ruby", "editing" }) do
  local loaded, examples = pcall(dofile, "tests/" .. suite .. ".lua")
  if not loaded then
    failures[#failures + 1] = suite .. ": " .. tostring(examples)
  else
    for name, example in pairs(examples) do
      support.reset()
      local ok, err = xpcall(example, debug.traceback)
      if ok then
        print("PASS " .. name)
      else
        failures[#failures + 1] = name .. ": " .. err
      end
    end
  end
end
vim.notify = notify
if #failures > 0 then
  io.stderr:write(table.concat(failures, "\n") .. "\n")
  vim.cmd("cquit 1")
else
  print("All TVIM behavior checks passed")
  vim.cmd("qa!")
end
