local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TopographyType = enums.TopographType
local TILE_SIZE = require("utils.constants").TILE_SIZE
local Vec2 = require("utils.Vec2")
local Shape = require("components.Shape")
local Texture = require("components.Texture")

---@class MapNode
---@field style TopographyType
---@field speedMultiplier number
---@field f integer
---@field g integer
---@field h integer
local MapNode = {}
MapNode.__index = MapNode

---comment
---@param entityManager EntityManager
---@param xIndex integer
---@param yIndex integer
---@return unknown
function MapNode.new(entityManager, xIndex, yIndex)
  local self = setmetatable({}, MapNode)
  self.f = 0
  self.g = 0
  self.h = 0

  self:setTopography()
  --temporary
  local color = { r = 0.0, g = 1.0, b = 0.0 } -- OPEN
  if self.style == TopographyType.ROUGH then
    color = { r = 0.0, g = 0.0, b = 1.0 }
  elseif self.style == TopographyType.INACCESSIBLE then
    color = { r = 1.0, g = 0.0, b = 0.0 }
  end
  --temporary

  local tileId = entityManager:createEntity()
  local pos = Vec2.new((xIndex - 1) * TILE_SIZE, (yIndex - 1) * TILE_SIZE)

  entityManager:addComponent(tileId, ComponentType.POSITION, pos)
  entityManager:addComponent(tileId, ComponentType.TEXTURE, Texture.new(color))
  entityManager:addComponent(tileId, ComponentType.SHAPE, Shape.new(ShapeType.SQUARE, TILE_SIZE))
  entityManager:addComponent(tileId, ComponentType.MAPCELL, self)
  return tileId
end

local TopographyMap = {
  [TopographyType.OPEN] = 1.0,
  [TopographyType.ROUGH] = 0.5,
  [TopographyType.INACCESSIBLE] = 0,
}

function MapNode:setTopography()
  local val = math.random()
  if val < 0.5 then
    self.style = TopographyType.OPEN
  elseif val < 0.85 then
    self.style = TopographyType.ROUGH
  else
    self.style = TopographyType.INACCESSIBLE
  end
  self.speedMultiplier = TopographyMap[self.style]
end

return MapNode
