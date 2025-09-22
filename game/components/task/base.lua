---@enum Priority
local Priority = {
  never = 0,
  veryLow = 1,
  low = 2,
  normal = 3,
  high = 4,
  veryHigh = 5,
  emergency = 6,
}

---@class Task
---@field performerEntity integer
---@field targetEntity integer
---@field priority Priority
local Task = {}
Task.__index = Task

---@param performerEntity integer
---@param targetEntity integer
function Task.new(performerEntity, targetEntity)
  local self = setmetatable({}, Task)
  self.performerEntity = performerEntity
  self.targetEntity = targetEntity
  self.priority = Priority.normal
end
