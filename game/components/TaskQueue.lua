local enums = require("game.utils.enums")
local MoveTo = require("game.components.MoveTo")
local Vec2 = require("game.utils.Vec2")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

---@class TaskQueue
---@field ownerId integer
---@field queue table<integer, Task>
---@field currentTask Task
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
  if self.currentTask then
    self.currentTask:perform(dt)
    if not self.currentTask.isComplete then
      return
    end
  end

  if #self.queue == 0 then
    return
  end

  self.currentTask = self:pop()
end

return TaskQueue
