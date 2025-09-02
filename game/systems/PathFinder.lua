local Vec2 = require("utils.Vec2")
local TILE_SIZE = require("utils.constants").TILE_SIZE
local enums = require("utils.enums")
local ShapeType = enums.ShapeType
local ComponentType = enums.ComponentType

local PathFinder = {}
PathFinder.__index = PathFinder

--- Simple A* implementation
function PathFinder.new()
	return setmetatable({}, PathFinder)
end

--- @param entityManager EntityManager
--- @param startEntity integer  -- entity that should start moving
--- @param goalEntity integer|Vec2   -- entity that represents the target (must have POSITION) or Vec2 Position for that entity
--- @return table
function PathFinder:findPath(entityManager, startEntity, goalEntity)
	local startingNode = entityManager:getComponent(startEntity, ComponentType.MAPCELL)
end

return PathFinder.new()
