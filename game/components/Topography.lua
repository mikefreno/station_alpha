---@class Topography
---@field style TopographyType
---@field speedMultiplier number
local Topography = {}
Topography.__index = Topography

---@param style TopographyType
---@param speedMultiplier number
function Topography.new(style, speedMultiplier)
    local self = setmetatable({}, Topography)
    self.style = style
    self.speedMultiplier = speedMultiplier
    return self
end

return Topography
