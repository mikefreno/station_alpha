local enums = require("utils.enums")
local TaskType = enums.TaskType
local scheduleColors = require("utils.colors").schedule

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
    [TaskType.FIREFIGHT] = 3,
    [TaskType.COMBAT] = 3,
    [TaskType.HUNT] = 3,
    [TaskType.CLEAN] = 3,
    [TaskType.RESEARCH] = 3,
    [TaskType.CROP_TEND] = 3,
    [TaskType.ANIMAL_TEND] = 3,
    [TaskType.DOCTOR] = 3,
    [TaskType.GUARD] = 3,
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

---@param taskType TaskType
function Schedule:setToMax(taskType)
  self.taskTable[taskType] = 6
end

---@param taskType TaskType
function Schedule:setToMin(taskType)
  self.taskTable[taskType] = 0
end

---@param taskType TaskType
function Schedule:increment(taskType)
  local currentVal = self.taskTable[taskType]
  if currentVal < 6 then
    self.taskTable[taskType] = currentVal + 1
  else
    self.taskTable[taskType] = 0
  end
end

---@param taskType TaskType
function Schedule:decrement(taskType)
  local currentVal = self.taskTable[taskType]
  if currentVal > 0 then
    self.taskTable[taskType] = currentVal - 1
  else
    self.taskTable[taskType] = 6
  end
end

---@param taskType TaskType
function Schedule:getStrVal(taskType)
  local currentVal = self.taskTable[taskType]
  if currentVal == -1 then
    return "N/A"
  end
  return tostring(currentVal)
end

---@param taskType TaskType
function Schedule:getColor(taskType)
  local currentVal = self.taskTable[taskType]
  return scheduleColors[currentVal]
end

return Schedule
