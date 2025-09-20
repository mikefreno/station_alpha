local enums = require("game.utils.enums")
local TaskType = enums.TaskType
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
