require "nvchad.options"

-- general config
vim.opt.colorcolumn = "140"
vim.opt.termguicolors = true

-- language config
vim.cmd [[ autocmd BufNewFile,BufRead *.bicep set filetype=bicep ]]
vim.cmd [[ autocmd BufNewFile, BufRead *.jbuilder set filetype=ruby ]]

vim.filetype.add {
  extension = {
    astro = "astro",
  },
}

vim.filetype.add {
  extension = {
    jbuilder = "ruby",
  },
}
