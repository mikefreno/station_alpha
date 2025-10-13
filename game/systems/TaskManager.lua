local enum = require("utils.enums")
local Task = require("components.task.base")
local ComponentType = enum.ComponentType
local TaskType = enum.TaskType
local Vec2 = require("utils.Vec2")
---this class servers to choose what the next task should be for its attached
---entity
---@class TaskManager
---@field openTasks table<TaskType, table<integer, Task>>
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
        local selectedTask = eSchedule:selectNextTask(self.openTasks)
        if selectedTask then
          tq:push(selectedTask)
        else
          --- start wander
        end
      end
    end
  end
end

---@param taskType TaskType
---@param task any
function TaskManager:addTask(taskType, task)
  table.insert(self.openTasks[taskType], task)
end

function TaskManager:removeTask() end

return TaskManager
