-- general config
vim.opt.colorcolumn = "140"

-- language config
vim.cmd [[ autocmd BufNewFile,BufRead *.bicep set filetype=bicep ]]

vim.filetype.add({
  extension = {
    astro = "astro"
  }
})
