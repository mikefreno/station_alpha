local enums = require("game.utils.enums")
local Vec2 = require("game.utils.Vec2")
local TopographyType = enums.TopographyType

---@class Tile
---@field position Vec2
---@field id number -- entity ID in EntityManager
---@field style TopographyType
---@field speedMultiplier number
---@field g number
---@field h number
---@field f number
---@field parent Tile?
---@field neighbors Tile[]
local Tile = {}
Tile.__index = Tile

---@param x integer
---@param y integer
---@param entityId  integer
---@param style TopographyType
---@param speedMult number
---@return Tile
function Tile.new(x, y, entityId, style, speedMult)
    local self = setmetatable({}, Tile)
    self.position = Vec2.new(x, y)
    self.id = entityId
    self.style = style
    self.speedMultiplier = speedMult
    self.g = 0
    self.h = 0
    self.f = 0
    self.parent = nil
    self.neighbors = {}
    return self
end

function Tile:updateStyle(newStyle) self.style = newStyle end

function Tile:reset()
    self.parent = nil
    self.position = nil
    self.g = 0
    self.h = 0
    self.f = 0
    self.tileId = nil
    self.style = TopographyType.OPEN
end

return Tile
