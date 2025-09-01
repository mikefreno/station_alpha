local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local Shapes = enums.Shapes
local Topography = enums.Topography
local TILE_SIZE = require("utils.constants").TILE_SIZE
local Vec2 = require("utils.Vec2")

---@class MapCell
local MapCell = {}
MapCell.__index = MapCell

---comment
---@param entityManager EntityManager
---@param xIndex integer
---@param yIndex integer
---@return unknown
function MapCell.new(entityManager, xIndex, yIndex)
	local self = setmetatable({}, MapCell)
	local topography = self:randomTopography()

	local tileId = entityManager:createEntity()
	local pos = Vec2.new((xIndex - 1) * TILE_SIZE, (yIndex - 1) * TILE_SIZE)

	Logger:debug("creation at " .. pos.x .. "," .. pos.y)

	entityManager:addComponent(tileId, ComponentType.POSITION, pos)

	local color = { r = 0.0, g = 1.0, b = 0.0 } -- OPEN
	if topography.style == Topography.ROUGH then
		color = { r = 0.0, g = 0.0, b = 1.0 }
	elseif topography.style == Topography.INACCESSIBLE then
		color = { r = 1.0, g = 0.0, b = 0.0 }
	end

	entityManager:addComponent(tileId, ComponentType.TEXTURE, { color = color })
	entityManager:addComponent(
		tileId,
		ComponentType.SHAPE,
		{ shape = Shapes.SQUARE, size = TILE_SIZE, border_only = true }
	)
	entityManager:addComponent(tileId, ComponentType.TRAVERSAL, topography)
	return tileId
end

---@return {style:Topography, speedMultiplier:number}
function MapCell:randomTopography()
	local val = math.random()
	if val < 0.5 then
		return { style = Topography.OPEN, speedMultiplier = 1.0 }
	elseif val < 0.85 then
		return { style = Topography.ROUGH, speedMultiplier = 0.5 }
	else
		return { style = Topography.INACCESSIBLE, speedMultiplier = 0.0 }
	end
end

return MapCell
