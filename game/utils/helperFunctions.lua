local Shape = require("components.Shape")
local Texture = require("components.Texture")
local Topography = require("components.Topography")
local Vec2 = require("utils.Vec2")
local TILE_SIZE = require("utils.constants").TILE_SIZE
local enums = require("utils.enums")
local TopographyType = enums.TopographyType
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType

local TopographyMap = {
  [TopographyType.OPEN] = 1.0,
  [TopographyType.ROUGH] = 0.5,
  [TopographyType.INACCESSIBLE] = 0,
}

local function getTopography()
  local val = math.random()
  if val < 0.5 then
    return {
      style = TopographyType.OPEN,
      speedMultiplier = TopographyMap[TopographyType.OPEN],
      color = { r = 0.0, g = 1.0, b = 0.0 },
    }
  elseif val < 0.85 then
    return {
      style = TopographyType.ROUGH,
      speedMultiplier = TopographyMap[TopographyType.ROUGH],
      color = { r = 0.0, g = 0.0, b = 1.0 },
    }
  else
    return {
      style = TopographyType.INACCESSIBLE,
      speedMultiplier = TopographyMap[TopographyType.INACCESSIBLE],
      color = { r = 1.0, g = 0.0, b = 0.0 },
    }
  end
end

---@param entityManager EntityManager
---@param xIndex integer
---@param yIndex integer
---@return unknown
local function createCell(entityManager, xIndex, yIndex)
  local result = getTopography()

  local tileId = entityManager:createEntity()

  entityManager:addComponent(
    tileId,
    ComponentType.POSITION,
    Vec2.new((xIndex - 1) * TILE_SIZE, (yIndex - 1) * TILE_SIZE)
  )
  entityManager:addComponent(tileId, ComponentType.TEXTURE, Texture.new(result.color))
  entityManager:addComponent(tileId, ComponentType.SHAPE, Shape.new(ShapeType.SQUARE, TILE_SIZE))
  entityManager:addComponent(tileId, ComponentType.TOPOGRAPHY, Topography.new(result.style, result.speedMultiplier))
  return tileId
end

---@param entityManager EntityManager
---@param width integer
---@param height integer
local function createLevelMap(entityManager, width, height)
  local tiles = {}
  for y = 1, height do
    for x = 1, width do
      local tileId = createCell(entityManager, x, y)
      table.insert(tiles, tileId)
    end
  end
end

local function compareTables(a, b)
  if a == b then
    return true
  end -- same reference
  if type(a) ~= "table" or type(b) ~= "table" then
    return false
  end

  for k, v in pairs(a) do
    if not compareTables(v, b[k]) then
      return false
    end
  end

  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end

  return true
end

return {
  createLevelMap = createLevelMap,
  compareTables = compareTables,
}
