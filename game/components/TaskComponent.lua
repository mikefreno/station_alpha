---@class TaskComponent
---@field target integer|Vec2 What/where to act upon (Entity ID or position)
---@field priority number Task priority (1-6, higher = more priority)
---@field isComplete boolean Completion status
---@field requiredDistance number How close to target needed (in tiles)
---@field estimatedDuration number Expected completion time (in seconds)
---@field entityId integer Owner entity ID
---@field startTime number When task was started (for progress calculation)
local TaskComponent = {}
TaskComponent.__index = TaskComponent

--- Constructor for TaskComponent
---@param target integer|Vec2? Target entity ID or position (nil for blank constructor)
---@param priority number? Priority level (1-6) (nil for blank constructor)
---@param requiredDistance number? Distance needed to target (default 1.0) (nil for blank constructor)
---@param estimatedDuration number? Expected task duration (default 1.0) (nil for blank constructor)
---@return TaskComponent?
function TaskComponent.new(target, priority, requiredDistance, estimatedDuration)
  local self = setmetatable({}, TaskComponent)

  -- Handle blank constructor for pooling
  if not target and not priority then
    self.target = nil
    self.priority = 1
    self.isComplete = false
    self.requiredDistance = 1.0
    self.estimatedDuration = 1.0
    self.entityId = nil
    self.startTime = love and love.timer and love.timer.getTime() or 0
    return self
  end

  -- Validate required parameters for regular constructor
  if not target then
    Logger:error("TaskComponent: target is required")
    return nil
  end

  if not priority or priority < 1 or priority > 6 then
    Logger:error("TaskComponent: priority must be between 1-6")
    return nil
  end

  self.target = target
  self.priority = priority
  self.isComplete = false
  self.requiredDistance = requiredDistance or 1.0
  self.estimatedDuration = estimatedDuration or 1.0
  self.entityId = nil -- Set when assigned to entity
  self.startTime = love and love.timer and love.timer.getTime() or 0

  return self
end

--- Create a new TaskComponent by extending this base class
---@param componentData table Component-specific data to merge
---@return TaskComponent Extended component
function TaskComponent:extend(componentData)
  local extended = {}

  -- Copy base TaskComponent methods and properties
  for key, value in pairs(self) do
    extended[key] = value
  end

  -- Merge component-specific data
  if componentData then
    for key, value in pairs(componentData) do
      extended[key] = value
    end
  end

  -- Set up metatable for inheritance
  extended.__index = extended

  return extended
end

--- Validates the task component state
---@return boolean True if task is valid
function TaskComponent:isValid()
  -- Check if target still exists (for entity targets)
  if type(self.target) == "number" then
    if not EntityManager.entities[self.target] then
      return false
    end
  end

  -- Check if owner entity still exists
  if self.entityId and not EntityManager.entities[self.entityId] then
    return false
  end

  return true
end

--- Marks the task as complete
function TaskComponent:markComplete()
  self.isComplete = true
end

--- Gets the progress of the task (0.0 to 1.0)
---@return number Progress percentage
function TaskComponent:getProgress()
  if self.isComplete then
    return 1.0
  end

  if not self.startTime or self.estimatedDuration <= 0 then
    return 0.0
  end

  local currentTime = love and love.timer and love.timer.getTime() or 0
  local elapsedTime = currentTime - self.startTime

  return math.min(elapsedTime / self.estimatedDuration, 1.0)
end

--- Gets the target position as a Vec2
---@return Vec2? Target position or nil if invalid
function TaskComponent:getTargetPosition()
  if type(self.target) == "table" and self.target.x and self.target.y then
    -- Target is already a Vec2
    return self.target
  elseif type(self.target) == "number" then
    -- Target is an entity ID, get its position
    local targetPos = EntityManager:getComponent(self.target, require("game.utils.enums").ComponentType.POSITION)
    if targetPos and type(targetPos) == "table" and targetPos.x and targetPos.y then
      return targetPos
    end
  end

  return nil
end

--- Checks if the entity is within required distance of the target
---@param entityPos Vec2 Current entity position
---@return boolean True if within required distance
function TaskComponent:isInRange(entityPos)
  local targetPos = self:getTargetPosition()
  if not targetPos or not entityPos then
    return false
  end

  local dx = entityPos.x - targetPos.x
  local dy = entityPos.y - targetPos.y
  local distance = math.sqrt(dx * dx + dy * dy)
  return distance <= self.requiredDistance
end

--- Creates a string representation for debugging
---@return string Debug string
function TaskComponent:toString()
  local targetStr = type(self.target) == "table" and string.format("Vec2(%.1f,%.1f)", self.target.x, self.target.y)
    or tostring(self.target)

  return string.format(
    "TaskComponent{target=%s, priority=%d, complete=%s, distance=%.1f}",
    targetStr,
    self.priority,
    tostring(self.isComplete),
    self.requiredDistance
  )
end

--- Reset component state for object pooling
--- Clears all data so component can be safely reused
function TaskComponent:reset()
  self.target = nil
  self.priority = 1
  self.isComplete = false
  self.requiredDistance = 1.0
  self.estimatedDuration = 1.0
  self.entityId = nil
  self.startTime = 0
  self._poolable = true
end

--- Initialize component with new data (for pool reuse)
---@param target integer|Vec2 Target entity ID or position
---@param priority number Priority level (1-6)
---@param requiredDistance number? Distance needed to target (default 1.0)
---@param estimatedDuration number? Expected task duration (default 1.0)
---@return boolean Success status
function TaskComponent:initialize(target, priority, requiredDistance, estimatedDuration)
  -- Validate required parameters
  if not target then
    Logger:error("TaskComponent:initialize - target is required")
    return false
  end

  if not priority or priority < 1 or priority > 6 then
    Logger:error("TaskComponent:initialize - priority must be between 1-6")
    return false
  end

  self.target = target
  self.priority = priority
  self.isComplete = false
  self.requiredDistance = requiredDistance or 1.0
  self.estimatedDuration = estimatedDuration or 1.0
  self.entityId = nil
  self.startTime = love and love.timer and love.timer.getTime() or 0

  return true
end

--- Check if this component is suitable for pooling
---@return boolean True if component can be pooled
function TaskComponent:isPoolable()
  return self._poolable == true and type(self.reset) == "function"
end

--- Sets the target for this task
---@param target integer|Vec2 Target entity ID or position
function TaskComponent:setTarget(target)
  if not target then
    Logger:error("TaskComponent:setTarget - target cannot be nil")
    return false
  end
  
  self.target = target
  return true
end

--- Gets the component type (should be overridden in subclasses)
---@return number ComponentType enum value
function TaskComponent:getComponentType()
  -- This is a base implementation - subclasses should override
  Logger:error("TaskComponent:getComponentType must be overridden in subclass")
  return nil
end

return TaskComponent
