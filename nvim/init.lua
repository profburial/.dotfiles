if vim.fn.has("nvim-0.12.5") ~= 1 then
  vim.api.nvim_err_writeln("TVIM requires Neovim >= 0.12.5; use stable 0.12.6 for the trial.")
  vim.cmd("cquit 1")
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "
require("options")
vim.cmd.filetype("plugin indent on")
vim.cmd.syntax("enable")

local lockfile = vim.fn.resolve(vim.fn.stdpath("config")) .. "/lazy-lock.json"
local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazy_path) then
  if vim.fn.executable("git") ~= 1 then
    vim.api.nvim_err_writeln("git clone for lazy.nvim failed (exit 127): install Git and retry TVIM.")
    vim.cmd("cquit 1")
  end
  local command =
    { "git", "clone", "--filter=blob:none", "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazy_path }
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    vim.api.nvim_err_writeln(
      table.concat(command, " ") .. " failed (exit " .. result.code .. "): " .. (result.stderr or "")
    )
    vim.cmd("cquit 1")
  end
  local revision = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))["lazy.nvim"].commit
  local checkout = { "git", "-C", lazy_path, "checkout", revision }
  local pinned = vim.system(checkout, { text = true }):wait()
  if pinned.code ~= 0 then
    vim.api.nvim_err_writeln(
      table.concat(checkout, " ") .. " failed (exit " .. pinned.code .. "): " .. (pinned.stderr or "")
    )
    vim.cmd("cquit 1")
  end
end
vim.opt.rtp:prepend(lazy_path)
require("lazy").setup({ { import = "plugins" } }, {
  lockfile = lockfile,
  checker = { enabled = false },
  change_detection = { notify = false },
})
vim.cmd.colorscheme("terry")
require("autocmds")
require("mappings")
