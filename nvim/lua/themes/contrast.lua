local M = {}

---@param hex string
---@return integer red, integer green, integer blue
local function channels(hex)
  local red, green, blue = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  assert(red, "expected a #rrggbb color, got " .. tostring(hex))
  return tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
end

---@param value integer
---@return number
local function linear(value)
  local scaled = value / 255
  if scaled <= 0.03928 then
    return scaled / 12.92
  end
  return ((scaled + 0.055) / 1.055) ^ 2.4
end

---@param hex string
---@return number
local function relative_luminance(hex)
  local red, green, blue = channels(hex)
  return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
end

---@param hex string
---@param amount number
---@return string
local function tint_toward_white(hex, amount)
  local red, green, blue = channels(hex)
  local function mix(value)
    return math.floor(value + (255 - value) * amount + 0.5)
  end
  return string.format("#%02x%02x%02x", mix(red), mix(green), mix(blue))
end

---WCAG contrast ratio between two `#rrggbb` colors, from 1 (identical) to 21.
---@param first string
---@param second string
---@return number
function M.ratio(first, second)
  local lighter, darker = relative_luminance(first), relative_luminance(second)
  if lighter < darker then
    lighter, darker = darker, lighter
  end
  return (lighter + 0.05) / (darker + 0.05)
end

---Return `foreground` when it already reads against `background` at `minimum_ratio`,
---otherwise the least white-tinted version of it that does.
---@param foreground string
---@param background string
---@param minimum_ratio number
---@return string
function M.readable(foreground, background, minimum_ratio)
  if M.ratio(foreground, background) >= minimum_ratio then
    return foreground
  end
  local too_dark, readable = 0, 1
  for _ = 1, 16 do
    local midpoint = (too_dark + readable) / 2
    if M.ratio(tint_toward_white(foreground, midpoint), background) >= minimum_ratio then
      readable = midpoint
    else
      too_dark = midpoint
    end
  end
  return tint_toward_white(foreground, readable)
end

return M
