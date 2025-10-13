local enums = require("utils.enums")
local TaskType = enums.TaskType
---@class Schedule
---@field taskTable table<TaskType, integer> --- 0 = never do, up to 6. 3 is neutral. 6 is emergency - will have visual queue, -1 is not assignable - it indicates an incapable task
local Schedule = {}
Schedule.__index = Schedule

function Schedule.new()
  local self = setmetatable({}, Schedule)
  self.taskTable = {
    [TaskType.MINE] = 3,
    [TaskType.CONSTRUCT] = 3,
    [TaskType.OPERATE] = 3,
    [TaskType.CROP_TEND] = 3,
    [TaskType.ANIMAL_TEND] = 3,
    [TaskType.DOCTOR] = 3,
    [TaskType.FIREFIGHT] = 3,
    [TaskType.COMBAT] = 3,
    [TaskType.GUARD] = 3,
    [TaskType.RESEARCH] = 3,
    [TaskType.CLEAN] = 3,
  }
  return self
end

---@param taskType TaskType
---@param newWeight integer
function Schedule:adjustScheduleWeight(taskType, newWeight)
  self.taskTable[taskType] = newWeight
end

---@param openTasks table<TaskType, table<integer, Task>>
---@return Task|nil
function Schedule:selectNextTask(openTasks)
  -- Iterate through priorities from highest (6) to lowest (1)
  for priority = 6, 1, -1 do
    -- Check each task type
    for taskType, weight in pairs(self.taskTable) do
      -- If this task type matches current priority and there are open tasks
      if weight == priority and openTasks[taskType] and #openTasks[taskType] > 0 then
        -- Return the first available task
        return table.remove(openTasks[taskType], 1)
      end
    end
  end

  -- No tasks found at any priority
  return nil
end

return Schedule
