local locked = vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
for name, revision in pairs(locked) do
  local path = vim.fn.stdpath("data"):gsub("/nvim$", "/tvim") .. "/lazy/" .. name
  local result = vim.system({ "git", "-C", path, "rev-parse", "HEAD" }, { text = true }):wait()
  assert(
    result.code == 0 and vim.trim(result.stdout) == revision.commit,
    "Plugin missing or revision mismatch: " .. name
  )
end

vim.opt.rtp:prepend(vim.fn.getcwd())
for _, parser in ipairs(require("configs.languages").parsers) do
  local path = vim.fn.stdpath("data"):gsub("/nvim$", "/tvim") .. "/site/parser/" .. parser .. ".so"
  assert(vim.uv.fs_stat(path), "Provision parser before offline tests: " .. parser .. ". See README Verification.")
end
