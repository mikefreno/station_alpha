local enum = require("game.utils.enums")
local ComponentType = enum.ComponentType
local TaskType = enum.TaskType
local Vec2 = require("game.utils.Vec2")
---this class servers to choose what the next task should be for its attached
---entity
---@class TaskManager
local TaskManager = {}
TaskManager.__index = TaskManager

---comment
---@return TaskManager
function TaskManager.new()
  local self = setmetatable({}, TaskManager)
  return self
end

---@param dt number
function TaskManager:update(dt)
  for e, _ in pairs(EntityManager.entities) do
    local tq = EntityManager:getComponent(e, ComponentType.TASKQUEUE)
    if tq then
      tq:update(dt)
      if #tq.queue == 0 then
        ---idling, create task
        EntityManager:getComponent(e, ComponentType.SCHEDULE)
      else
        Logger:debug(#tq.queue)
      end
    end
  end
end

---@param entity integer
---@param path table<integer, {type:TaskType, data:Vec2}>
function TaskManager:newPath(entity, path)
  if path and #path > 0 then
    local taskQueue = EntityManager:getComponent(entity, ComponentType.TASKQUEUE)
    if taskQueue then
      taskQueue:reset()
      for _, wp in ipairs(path) do
        taskQueue:push(wp)
      end
    end
  end
end

return TaskManager
