local enums = require("game.utils.enums")
local MoveTo = require("game.components.MoveTo")
local Vec2 = require("game.utils.Vec2")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

---@class TaskQueue
---@field ownerId integer
---@field queue table<integer, Task>
---@field currentTask MoveTo?
local TaskQueue = {}

---@param ownerId integer
function TaskQueue.new(ownerId)
  local self = setmetatable({}, { __index = TaskQueue })
  self.ownerId = ownerId
  self.queue = {}
  self.currentTask = nil
  return self
end

function TaskQueue:reset()
  self.queue = {}
  self.currentTask = nil
end

function TaskQueue:push(task)
  table.insert(self.queue, task)
end

function TaskQueue:pop()
  return table.remove(self.queue, 1)
end

---@param dt number
function TaskQueue:update(dt)
  local function cleanup()
    --align
    local p = EntityManager:getComponent(self.ownerId, ComponentType.POSITION)
    local v = EntityManager:getComponent(self.ownerId, ComponentType.VELOCITY)
    v = Vec2.new(0, 0)
    p = self.currentTask.target
    --clear
    self.currentTask = nil
  end
  if self.currentTask then
    local calledCleanup = self.currentTask:update(self.ownerId, cleanup)
    if not calledCleanup then
      return
    end
  end
  -- If no current task, start the next one
  if #self.queue == 0 then
    return
  end

  local nextTask = self:pop()
  if nextTask.type == TaskType.MOVETO then
    self.currentTask = MoveTo.new(nextTask.data)
    EntityManager:addComponent(self.ownerId, ComponentType.MOVETO, self.currentTask)
  else
    -- First detect if we are at the target entity
  end
end

return TaskQueue
