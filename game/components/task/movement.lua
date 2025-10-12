local Task = require("game.components.task.base")
local ComponentType = require("game.utils.enums").ComponentType
local Vec2 = require("game.utils.Vec2")

---@class MovementTask: Task
---@field startPosition Vec2
---@field targetPosition Vec2
---@field currentPathIndex integer
---@field path table
local MovementTask = setmetatable({}, { __index = Task })
MovementTask.__index = MovementTask

---@param performerEntity integer
---@param target integer|Vec2
---@param priority? Priority
function MovementTask.new(performerEntity, target, priority)
  local self = Task.new(performerEntity, target, priority)
  --- @cast self MovementTask
  self.startPosition = EntityManager:getComponent(performerEntity, ComponentType.POSITION)
  if type(target) == "number" then
    self.targetPosition = EntityManager:getComponent(target, ComponentType.POSITION)
  elseif type(target) == "table" then
    self.targetPosition = target
  end
  local path = Pathfinder:findPath(
    Vec2.new(math.floor(self.startPosition.x), math.floor(self.startPosition.y)),
    self.targetPosition
  )
  if path == nil then
    Logger:error("Failed to generate MovementTask (path failure)")
    return
  end
  self.path = path
  self.currentPathIndex = 0
  return setmetatable(self, MovementTask)
end

function MovementTask:perform(dt)
  Logger:debug("performing")
  local moveto = EntityManager:getComponent(self.performerEntity, ComponentType.MOVETO)
  if moveto then
    Logger:debug("waiting on position system")
    -- The position system removes these when ready
    return
  end
  if self.currentPathIndex > #self.path then
    self.isComplete = true
    return
  end
  Logger:debug("making moveto")
  self.currentPathIndex = self.currentPathIndex + 1
  local nextPoint = self.path[self.currentPathIndex]
  EntityManager:addComponent(self.performerEntity, ComponentType.MOVETO, nextPoint)
end

return MovementTask
