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
--- @param start Vec2
--- @param target Vec2
--- @return table
function PathFinder:findPath(entityManager, start, target)
  local startingNode = entityManager:find(ComponentType.MAPNODE, start)
  Logger:debug(startingNode)
  --if startingNode then
  --Logger:error("Missing startingNode for PathFinder")
  return {}
  --end
end

return PathFinder.new()
