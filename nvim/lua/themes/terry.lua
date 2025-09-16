local M = {}

M.base_30 = {
  white = "#ffffff",
  darker_black = "#191828",
  black = "#2b3e50", --  nvim bg
  black2 = "#243443",
  one_bg = "#2b3e50", -- real bg of onedark
  one_bg2 = "#2b3e50",
  one_bg3 = "#2b3e50",
  grey = "#d5d8dc",
  grey_fg = "#bfc5cb",
  grey_fg2 = "#555464",
  light_grey = "#eaecee",
  red = "#de4242",
  baby_pink = "#ffa5c3",
  pink = "#F5C2E7",
  line = "#383747", -- for lines like vertsplit
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
  lavender = "#c7d1ff",
}

M.base_16 = {
  -- base00 = "#2b3e50",
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

M.polish_hl = {
  ["@variable"] = { fg = M.base_30.light_grey },
  ["@property"] = { fg = M.base_30.white },
  ["@variable.builtin"] = { fg = M.base_30.yellow },
}

M.type = "dark"

M = require("base46").override_theme(M, "terry")

return M
