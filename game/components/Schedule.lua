local enums = require("game.utils.enums")
local TaskType = enums.TaskType
local ComponentType = enums.ComponentType
local Logger = require("logger")

---@class Schedule
---@field taskTable table<TaskType, integer> --- 0 = never do, up to 6. 3 is neutral. 6 is emergency - will have visual queue
local Schedule = {}
Schedule.__index = Schedule

function Schedule.new()
  local self = setmetatable({}, Schedule)
  self.taskTable = {
    [TaskType.MINE] = 0,
    [TaskType.CONSTRUCT] = 0,
    [TaskType.OPERATE] = 0,
    [TaskType.CROP_TEND] = 0,
    [TaskType.ANIMAL_TEND] = 0,
    [TaskType.DOCTOR] = 0,
    [TaskType.FIREFIGHT] = 0,
    [TaskType.COMBAT] = 0,
    [TaskType.GUARD] = 0,
    [TaskType.RESEARCH] = 0,
    [TaskType.CLEAN] = 0,
  }
  return self
end

---@param taskType TaskType
---@param newWeight integer
function Schedule:adjustScheduleWeight(taskType, newWeight)
  self.taskTable[taskType] = newWeight
end

---Get the schedule weight for a task type
---@param taskType TaskType
---@return integer weight The weight for the task type (0-6)
function Schedule:getScheduleWeight(taskType)
  return self.taskTable[taskType] or 0
end

---ECS-compatible method that returns task type and target instead of Task object
---@param openTasks table<TaskType, table<integer, any>>
---@return TaskType|nil, any|nil taskType, target
function Schedule:selectNextTaskType(openTasks)
  -- Iterate through priorities from highest (6) to lowest (1)
  for priority = 6, 1, -1 do
    -- Check each task type
    for taskType, weight in pairs(self.taskTable) do
      -- If this task type matches current priority and there are open tasks
      if weight == priority and openTasks[taskType] and #openTasks[taskType] > 0 then
        -- Return the task type and target
        local target = table.remove(openTasks[taskType], 1)
        return taskType, target
      end
    end
  end

  -- No tasks found at any priority
  return nil, nil
end

---Unified method for ECS task selection
---@param openTasks table<TaskType, table<integer, any>>
---@param taskManager table TaskManager instance for ECS task creation
---@param entityId integer Entity ID for ECS task assignment
---@return any|nil task Returns TaskType on success, or nil
function Schedule:selectTask(openTasks, taskManager, entityId)
  -- ECS mode: return task type for TaskManager to create ECS component
  local taskType, target = self:selectNextTaskType(openTasks)
  if taskType and target then
    -- Let TaskManager create the appropriate ECS task component
    local success = taskManager:createECSTask(taskType, target, entityId, 1.0)
    if success then
      return taskType -- Return task type to indicate success
    end
  end
  return nil
end

return Schedule
