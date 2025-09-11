-- Utility class for color handling
---@class Color
---@field r number
---@field g number
---@field b number
---@field a number
local Color = {}
Color.__index = Color

--- Create a new color instance
---@param r number
---@param g number
---@param b number
---@param a number? -- default 1
---@return Color
function Color.new(r, g, b, a)
  local self = setmetatable({}, Color)
  self.r = r or 0
  self.g = g or 0
  self.b = b or 0
  self.a = a or 1
  return self
end

--- Convert hex string to color
---@param hex string -- e.g. "#RRGGBB" or "#RRGGBBAA"
---@return Color
function Color.fromHex(hex)
  local hex = hex:gsub("#", "")
  if #hex == 6 then
    local r = tonumber("0x" .. hex:sub(1, 2))
    local g = tonumber("0x" .. hex:sub(3, 4))
    local b = tonumber("0x" .. hex:sub(5, 6))
    return Color.new(r, g, b, 1)
  elseif #hex == 8 then
    local r = tonumber("0x" .. hex:sub(1, 2))
    local g = tonumber("0x" .. hex:sub(3, 4))
    local b = tonumber("0x" .. hex:sub(5, 6))
    local a = tonumber("0x" .. hex:sub(7, 8)) / 255
    return Color.new(r, g, b, a)
  else
    error("Invalid hex string")
  end
end

--- Convert color to hex string
---@return string
function Color:toHex()
  local r = math.floor(self.r * 255)
  local g = math.floor(self.g * 255)
  local b = math.floor(self.b * 255)
  local a = math.floor(self.a * 255)
  if self.a ~= 1 then
    return string.format("#%02X%02X%02X%02X", r, g, b, a)
  else
    return string.format("#%02X%02X%02X", r, g, b)
  end
end

---@return number r, number g, number b, number a
function Color:toRGBA()
  return self.r, self.g, self.b, self.a
end

return Color
