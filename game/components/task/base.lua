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
---@field target integer|Vec2 -- Entity or world position
---@field priority Priority
---@field isComplete boolean
local Task = {}
Task.__index = Task

---@param performerEntity integer
---@param target integer|Vec2
---@param priority? Priority
function Task.new(performerEntity, target, priority)
  local self = setmetatable({}, Task)
  self.performerEntity = performerEntity
  self.target = target
  self.priority = priority or Priority.normal
  self.isComplete = false
  return self
end

return Task
