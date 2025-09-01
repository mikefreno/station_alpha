local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local Shapes = enums.Shapes
local TILE_SIZE = require("utils.constants").TILE_SIZE
local Vec2 = require("utils.Vec2")

---@class MapCell
---@field position Vec2
local MapCell = {}
MapCell.__index = MapCell

---comment
---@param entityManager any
---@param xIndex integer
---@param yIndex integer
---@return unknown
function MapCell.new(entityManager, xIndex, yIndex)
	local tileId = entityManager:createEntity()
	entityManager:addComponent(
		tileId,
		ComponentType.POSITION,
		Vec2.new((xIndex - 1) * TILE_SIZE, (yIndex - 1) * TILE_SIZE)
	)
	entityManager:addComponent(tileId, ComponentType.TEXTURE, { color = { r = 0.5, g = 0.5, b = 0.5 } })
	entityManager:addComponent(
		tileId,
		ComponentType.SHAPE,
		{ shape = Shapes.SQUARE, size = TILE_SIZE, border_only = true }
	)
	return tileId
end

return MapCell
