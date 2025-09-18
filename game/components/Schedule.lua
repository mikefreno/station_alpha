local enums = require("game.utils.enums")
local TaskType = enums.TaskType
---@class Schedule
---@field taskTable table<TaskType, integer>
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
end

---@param taskType TaskType
---@param newWeight integer
function Schedule:adjustScheduleWeight(taskType, newWeight)
  self.taskTable[TaskType] = newWeight
end

---@param openTasks table<integer, Task>
function Schedule:selectNextTask(openTasks)
  for i, task in ipairs(openTasks) do
  end
end

return Schedule
