local options = {
  laststatus = 3,
  showmode = false,
  splitkeep = "screen",
  clipboard = "unnamedplus",
  cursorline = true,
  cursorlineopt = "number",
  expandtab = true,
  shiftwidth = 2,
  smartindent = true,
  tabstop = 2,
  softtabstop = 2,
  ignorecase = true,
  smartcase = true,
  mouse = "a",
  number = true,
  relativenumber = true,
  numberwidth = 2,
  ruler = false,
  signcolumn = "yes",
  splitbelow = true,
  splitright = true,
  timeoutlen = 400,
  undofile = true,
  updatetime = 250,
  colorcolumn = "140",
  termguicolors = true,
}
for name, value in pairs(options) do
  vim.o[name] = value
end
vim.opt.fillchars = { eob = " " }
vim.opt.shortmess:append("sI")
vim.opt.whichwrap:append("<>[]hl")
for _, provider in ipairs({ "node", "python3", "perl", "ruby" }) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end
vim.filetype.add({ extension = { astro = "astro", bicep = "bicep", jbuilder = "ruby" } })

local severity = vim.diagnostic.severity
vim.diagnostic.config({
  virtual_text = { prefix = "" },
  signs = {
    text = { [severity.ERROR] = "󰅙", [severity.WARN] = "", [severity.INFO] = "󰋼", [severity.HINT] = "󰌵" },
  },
  underline = true,
  float = { border = "single" },
})
