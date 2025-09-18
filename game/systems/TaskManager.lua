local enum = require("game.utils.enums")
local Task = require("game.components.Task")
local ComponentType = enum.ComponentType
local TaskType = enum.TaskType
local Vec2 = require("game.utils.Vec2")
---this class servers to choose what the next task should be for its attached
---entity
---@class TaskManager
---@field openTasks table<TaskType, table>
local TaskManager = {}
TaskManager.__index = TaskManager

---comment
---@return TaskManager
function TaskManager.new()
  local self = setmetatable({}, TaskManager)
  self.openTasks = {}
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
        local eSchedule = EntityManager:getComponent(e, ComponentType.SCHEDULE)
        if not eSchedule then
          return
        end
        eSchedule:selectNextTask(self.openTasks)
      end
    end
  end
end

---@param taskType TaskType
---@param task any
function TaskManager:addTask(taskType, task)
  table.insert(self.openTasks[taskType], task)
end

---helper function to add a full path in sequence to the queue
---@param entity integer
---@param path table<integer, Vec2>
function TaskManager:newPath(entity, path)
  if path and #path > 0 then
    local taskQueue = EntityManager:getComponent(entity, ComponentType.TASKQUEUE)
    if taskQueue then
      taskQueue:reset()
      for _, wp in ipairs(path) do
        taskQueue:push(Task.new(TaskType.MOVETO, wp))
      end
    end
  end
end

return TaskManager
