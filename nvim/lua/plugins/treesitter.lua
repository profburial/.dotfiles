---@type LazySpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    ---@return nil
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup({})
      local warned = {}
      ---@param bufnr integer
      ---@return nil
      local function activate(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
          return
        end
        local language = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
        if not language then
          return
        end
        local available = pcall(vim.treesitter.language.add, language)
        if not available then
          if not warned[language] then
            warned[language] = true
            vim.notify(
              "Parser unavailable for "
                .. language
                .. "; use :TSInstall "
                .. language
                .. " after checking tree-sitter and compiler prerequisites.",
              vim.log.levels.WARN
            )
          end
          return
        end
        local started = pcall(vim.treesitter.start, bufnr, language)
        if started and vim.treesitter.query.get(language, "indents") then
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end
      local group = vim.api.nvim_create_augroup("TvimTreesitter", { clear = true })
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        group = group,
        ---@param event vim.api.keyset.create_autocmd.callback_args
        ---@return nil
        callback = function(event)
          activate(event.buf)
        end,
      })
      treesitter.install(require("configs.languages").parsers):await(function(err)
        vim.schedule(function()
          if err then
            vim.notify(
              "Parser installation failed: " .. tostring(err) .. "; inspect :messages and retry :TSInstall.",
              vim.log.levels.ERROR
            )
          end
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) then
              activate(bufnr)
            end
          end
        end)
      end)
    end,
  },
}
