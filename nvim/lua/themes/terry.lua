local palette = {}

palette.base_30 = {
  white = "#ffffff",
  darker_black = "#191828",
  black = "#2b3e50",
  black2 = "#243443",
  one_bg = "#2b3e50",
  one_bg2 = "#2b3e50",
  one_bg3 = "#2b3e50",
  grey = "#d5d8dc",
  grey_fg = "#bfc5cb",
  grey_fg2 = "#555464",
  light_grey = "#eaecee",
  red = "#de4242",
  baby_pink = "#ffa5c3",
  pink = "#F5C2E7",
  line = "#383747",
  green = "#ABE9B3",
  vibrant_green = "#b6f4be",
  nord_blue = "#8bc2f0",
  blue = "#89B4FA",
  yellow = "#e6db74",
  sun = "#ffe9b6",
  purple = "#d0a9e5",
  dark_purple = "#c7a0dc",
  teal = "#B5E8E0",
  orange = "#F8BD96",
  cyan = "#89DCEB",
  statusline_bg = "#232232",
  lightbg = "#2f2e3e",
  pmenu_bg = "#ABE9B3",
  folder_bg = "#89B4FA",
  tree_guide = "#6f8398",
  lavender = "#c7d1ff",
}

palette.base_16 = {
  base00 = "#263645",
  base01 = "#243443",
  base02 = "#19242f",
  base03 = "#ffffff",
  base04 = "#ffffff",
  base05 = "#ffffff",
  base06 = "#ffffff",
  base07 = "#ffffff",
  base08 = "#ffffff",
  base09 = "#F8BD96",
  base0A = "#FAE3B0",
  base0B = "#ABE9B3",
  base0C = "#33c442",
  base0D = "#699ff5",
  base0E = "#DE6554",
  base0F = "#F38BA8",
}

local contrast = require("themes.contrast")

-- Devicons brand colors assume a near-black background; on Terry's slate tree many fall below WCAG AA.
local MINIMUM_ICON_CONTRAST = 4.5

local M = {}

---Lighten file-type icon colors that would be hard to read on the file tree background.
---Icons that already meet the contrast threshold keep their upstream color.
---@return nil
function M.apply_readable_file_icons()
  local devicons = require("nvim-web-devicons")
  local background = palette.base_30.black
  local lightened = {}
  for key, icon in pairs(devicons.get_icons()) do
    if icon.color then
      local color = contrast.readable(icon.color, background, MINIMUM_ICON_CONTRAST)
      if color ~= icon.color then
        lightened[key] = vim.tbl_extend("force", icon, { color = color })
      end
    end
  end
  devicons.set_icon(lightened)
end

---Apply Terry across retained editor interfaces.
---@return nil
function M.apply()
  vim.cmd.highlight("clear")
  vim.o.background = "dark"
  vim.g.colors_name = "terry"
  local p, b = palette.base_30, palette.base_16
  local groups = {
    Normal = { fg = b.base05, bg = b.base00 },
    NormalFloat = { fg = p.white, bg = p.black },
    FloatBorder = { fg = p.line, bg = p.black },
    NormalNC = { fg = b.base05, bg = b.base00 },
    EndOfBuffer = { fg = b.base00 },
    Comment = { fg = p.grey_fg2 },
    LineNr = { fg = p.grey_fg2 },
    CursorLineNr = { fg = p.white, bold = true },
    CursorLine = { bg = b.base01 },
    ColorColumn = { bg = b.base01 },
    SignColumn = { bg = b.base00 },
    WinSeparator = { fg = p.line },
    Visual = { bg = b.base02 },
    Search = { fg = p.black, bg = p.yellow },
    IncSearch = { fg = p.black, bg = p.orange },
    MatchParen = { fg = p.blue, bold = true },
    Pmenu = { fg = p.white, bg = p.black },
    PmenuSel = { fg = p.black, bg = p.pmenu_bg },
    PmenuSbar = { bg = p.black2 },
    PmenuThumb = { bg = p.grey_fg2 },
    StatusLine = { fg = p.white, bg = p.statusline_bg },
    StatusLineNC = { fg = p.grey_fg, bg = p.statusline_bg },
    TabLine = { fg = p.grey_fg, bg = p.black },
    TabLineSel = { fg = p.white, bg = b.base00 },
    TabLineFill = { bg = p.black },
    String = { fg = b.base0B },
    Character = { fg = b.base0B },
    Number = { fg = b.base09 },
    Boolean = { fg = b.base09 },
    Constant = { fg = b.base09 },
    Identifier = { fg = b.base08 },
    Function = { fg = b.base0D },
    Statement = { fg = b.base0E },
    Keyword = { fg = b.base0E },
    Operator = { fg = b.base05 },
    PreProc = { fg = b.base0A },
    Type = { fg = b.base0A },
    Special = { fg = b.base0C },
    Delimiter = { fg = b.base05 },
    Error = { fg = p.red },
    Todo = { fg = p.yellow, bold = true },
    ["@variable"] = { fg = p.light_grey },
    ["@property"] = { fg = p.white },
    ["@variable.builtin"] = { fg = p.yellow },
    ["@function"] = { fg = b.base0D },
    ["@keyword"] = { fg = b.base0E },
    ["@type"] = { fg = b.base0A },
    ["@string"] = { fg = b.base0B },
    ["@comment"] = { fg = p.grey_fg2 },
    NvimTreeNormal = { fg = p.white, bg = p.black },
    NvimTreeNormalNC = { fg = p.white, bg = p.black },
    NvimTreeFolderName = { fg = p.folder_bg },
    NvimTreeOpenedFolderName = { fg = p.folder_bg, bold = true },
    NvimTreeFolderIcon = { fg = p.folder_bg },
    NvimTreeIndentMarker = { fg = p.tree_guide },
    NvimTreeFolderArrowClosed = { fg = p.grey_fg },
    NvimTreeFolderArrowOpen = { fg = p.grey_fg },
    NvimTreeGitDirty = { fg = p.yellow },
    NvimTreeGitNew = { fg = p.green },
    NvimTreeGitDeleted = { fg = p.red },
    NvimTreeWinSeparator = { fg = p.black, bg = p.black },
    TelescopeNormal = { fg = p.white, bg = p.black },
    TelescopeBorder = { fg = p.black, bg = p.black },
    TelescopePromptNormal = { fg = p.white, bg = p.black2 },
    TelescopePromptBorder = { fg = p.black2, bg = p.black2 },
    TelescopePromptPrefix = { fg = p.red, bg = p.black2 },
    TelescopePromptTitle = { fg = p.black, bg = p.red },
    TelescopePreviewTitle = { fg = p.black, bg = p.green },
    TelescopeResultsTitle = { fg = p.black, bg = p.black },
    TelescopeSelection = { bg = p.black2 },
    TelescopeMatching = { fg = p.blue },
    CmpItemAbbr = { fg = p.white },
    CmpItemAbbrMatch = { fg = p.blue, bold = true },
    CmpItemAbbrDeprecated = { fg = p.grey_fg2, strikethrough = true },
    CmpItemMenu = { fg = p.grey_fg },
    CmpItemKind = { fg = p.blue },
    BufferLineFill = { bg = p.black },
    BufferLineBackground = { fg = p.grey_fg, bg = p.black },
    BufferLineBufferSelected = { fg = p.white, bg = b.base00, bold = true },
    BufferLineBufferVisible = { fg = p.white, bg = p.black2 },
    BufferLineModified = { fg = p.yellow, bg = p.black },
    BufferLineModifiedSelected = { fg = p.yellow, bg = b.base00 },
    BufferLineIndicatorSelected = { fg = p.blue, bg = b.base00 },
    WhichKey = { fg = p.blue },
    WhichKeyGroup = { fg = p.purple },
    WhichKeyDesc = { fg = p.white },
    WhichKeyNormal = { bg = p.black },
    IblIndent = { fg = p.line },
    IblScope = { fg = p.grey_fg2 },
    GitSignsAdd = { fg = p.green },
    GitSignsChange = { fg = p.blue },
    GitSignsDelete = { fg = p.red },
    DiffAdd = { bg = "#304b44" },
    DiffChange = { bg = p.black2 },
    DiffDelete = { fg = p.red, bg = p.black2 },
    DiffText = { bg = "#3b5069" },
  }
  for severity, color in pairs({ Error = p.red, Warn = p.yellow, Info = p.blue, Hint = p.purple }) do
    groups["Diagnostic" .. severity] = { fg = color }
    groups["DiagnosticVirtualText" .. severity] = { fg = color }
    groups["DiagnosticUnderline" .. severity] = { sp = color, undercurl = true }
  end
  for name, attributes in pairs(groups) do
    vim.api.nvim_set_hl(0, name, attributes)
  end
end

return M
