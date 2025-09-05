---@class Texture
---@field color {r:number, g:number, b:number}
local Texture = {}
Texture.__index = Texture

---@param color {r:number, g:number, b:number}
function Texture.new(color)
    local self = setmetatable({}, Texture)
    self.color = color
    return self
end

return Texture
