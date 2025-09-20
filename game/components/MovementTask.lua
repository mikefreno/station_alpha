local TaskComponent = require("components.TaskComponent")

---@class MovementTask : TaskComponent
---@field path Vec2[] Current path to follow
---@field currentWaypoint number Index in path array (1-based for Lua)
---@field targetPosition Vec2 Final destination
---@field movementSpeed number Movement rate modifier (default 1.0)
---@field totalDistance number Total path distance for progress calculation
local MovementTask = {}
MovementTask.__index = MovementTask

--- Constructor for MovementTask
---@param targetPosition Vec2? Final destination position (nil for pooled components)
---@param requiredDistance number? Distance needed to target (default 0.5)
---@param movementSpeed number? Movement speed modifier (default 1.0)
---@return MovementTask?
function MovementTask.new(targetPosition, requiredDistance, movementSpeed)
  -- Allow creating blank components for object pooling
  if not targetPosition then
    local self = {}
    
    -- Copy methods from TaskComponent
    local methodsToSkip = { new = true, getProgress = true, toString = true }
    for k, v in pairs(TaskComponent) do
      if type(v) == "function" and not methodsToSkip[k] then
        self[k] = v
      end
    end
    
    -- Copy methods from MovementTask
    for k, v in pairs(MovementTask) do
      if type(v) == "function" and k ~= "new" then
        self[k] = v
      end
    end
    
    setmetatable(self, MovementTask)
    
    -- Add MovementTask-specific properties with default values
    self.path = {}
    self.currentWaypoint = 1
    self.targetPosition = nil
    self.movementSpeed = 1.0
    self.totalDistance = 0
    
    -- Mark as poolable
    self._poolable = true
    
    return self
  end
  
  -- Normal constructor validation for non-pooled components
  if not targetPosition.x or not targetPosition.y then
    Logger:error("MovementTask: targetPosition must be a valid Vec2")
    return nil
  end

  -- Create base task component with Vec2 target and priority 6 (highest)
  local base = TaskComponent.new(targetPosition, 6, requiredDistance or 0.5, 1.0)
  if not base then
    return nil
  end

  -- Create MovementTask instance with TaskComponent as base
  local self = {}
  for k, v in pairs(base) do
    self[k] = v
  end

  -- Copy methods from TaskComponent (except ones we override)
  local methodsToSkip = { new = true, getProgress = true, toString = true }
  for k, v in pairs(TaskComponent) do
    if type(v) == "function" and not methodsToSkip[k] then
      self[k] = v
    end
  end

  setmetatable(self, MovementTask)

  -- Add MovementTask-specific properties
  self.path = {}
  self.currentWaypoint = 1
  self.targetPosition = targetPosition
  self.movementSpeed = movementSpeed or 1.0
  self.totalDistance = 0

  return self
end

--- Sets a new path for the movement task
---@param path Vec2[] Array of waypoint positions
function MovementTask:setPath(path)
  if not path or #path == 0 then
    Logger:error("MovementTask: path cannot be empty")
    return
  end

  self.path = path
  self.currentWaypoint = 1
  self.totalDistance = self:calculateTotalDistance()

  -- Update the task's target to the final destination
  self.target = path[#path]
  self.targetPosition = path[#path]
end

--- Calculates the total distance of the entire path
---@return number Total path distance
function MovementTask:calculateTotalDistance()
  if #self.path < 2 then
    return 0
  end

  local total = 0
  for i = 1, #self.path - 1 do
    local current = self.path[i]
    local next = self.path[i + 1]
    local dx = next.x - current.x
    local dy = next.y - current.y
    total = total + math.sqrt(dx * dx + dy * dy)
  end

  return total
end

--- Gets the current waypoint target position
---@return Vec2? Current waypoint or nil if path complete
function MovementTask:getCurrentTarget()
  if self.currentWaypoint <= #self.path then
    return self.path[self.currentWaypoint]
  end
  return nil
end

--- Advances to the next waypoint in the path
---@return boolean True if advanced, false if at end of path
function MovementTask:advanceWaypoint()
  if self.currentWaypoint < #self.path then
    self.currentWaypoint = self.currentWaypoint + 1
    return true
  end
  return false
end

--- Checks if entity is at the current waypoint
---@param currentPos Vec2 Current entity position
---@param waypointTolerance number? Distance tolerance for waypoint (default 0.1)
---@return boolean True if at current waypoint
function MovementTask:isAtCurrentWaypoint(currentPos, waypointTolerance)
  local target = self:getCurrentTarget()
  if not target or not currentPos then
    return false
  end

  local tolerance = waypointTolerance or 0.1
  local dx = currentPos.x - target.x
  local dy = currentPos.y - target.y
  local distance = math.sqrt(dx * dx + dy * dy)

  return distance <= tolerance
end

--- Checks if entity is at the final destination
---@param currentPos Vec2 Current entity position
---@return boolean True if at destination within required distance
function MovementTask:isAtDestination(currentPos)
  if not currentPos then
    return false
  end

  local dx = currentPos.x - self.targetPosition.x
  local dy = currentPos.y - self.targetPosition.y
  local distance = math.sqrt(dx * dx + dy * dy)

  return distance <= self.requiredDistance
end

--- Updates movement task state (call this each frame for moving entities)
---@param currentPos Vec2 Current entity position
---@return boolean True if movement should continue, false if complete
function MovementTask:update(currentPos)
  if self.isComplete then
    return false
  end

  -- Check if we've reached the final destination
  if self:isAtDestination(currentPos) then
    self:markComplete()
    return false
  end

  -- Check if we need to advance to the next waypoint
  if self:isAtCurrentWaypoint(currentPos) then
    if not self:advanceWaypoint() then
      -- Reached end of path, check final destination again
      if self:isAtDestination(currentPos) then
        self:markComplete()
        return false
      end
    end
  end

  return true -- Continue movement
end

--- Gets movement progress along the path (0.0 to 1.0)
---@param currentPos Vec2? Current entity position for accurate calculation
---@return number Progress percentage
function MovementTask:getProgress(currentPos)
  if self.isComplete then
    return 1.0
  end

  if #self.path < 2 or self.totalDistance <= 0 then
    return 0.0
  end

  -- If no current position provided, estimate based on waypoint progress
  if not currentPos then
    local waypointProgress = (self.currentWaypoint - 1) / (#self.path - 1)
    return math.min(waypointProgress, 1.0)
  end

  -- Calculate actual distance from start of path to current position
  local startPoint = self.path[1]
  local dx = currentPos.x - startPoint.x
  local dy = currentPos.y - startPoint.y
  local distanceFromStart = math.sqrt(dx * dx + dy * dy)

  return math.min(distanceFromStart / self.totalDistance, 1.0)
end

--- Checks if the movement task has a valid path
---@return boolean True if path is valid and not empty
function MovementTask:hasValidPath()
  return #self.path > 0
end

--- Gets the remaining distance to the final destination
---@param currentPos Vec2 Current entity position
---@return number Distance remaining
function MovementTask:getRemainingDistance(currentPos)
  if not currentPos then
    return self.totalDistance
  end

  local dx = currentPos.x - self.targetPosition.x
  local dy = currentPos.y - self.targetPosition.y
  return math.sqrt(dx * dx + dy * dy)
end

--- Creates a string representation for debugging
---@return string Debug string
function MovementTask:toString()
  return string.format(
    "MovementTask{target=Vec2(%.1f,%.1f), waypoint=%d/%d, speed=%.1f, complete=%s}",
    self.targetPosition.x,
    self.targetPosition.y,
    self.currentWaypoint,
    #self.path,
    self.movementSpeed,
    tostring(self.isComplete)
  )
end

--- Reset component state for object pooling
function MovementTask:reset()
  -- Reset base TaskComponent properties
  TaskComponent.reset(self)

  -- Reset MovementTask-specific properties
  self.path = {}
  self.currentWaypoint = 1
  self.targetPosition = nil
  self.movementSpeed = 1.0
  self.totalDistance = 0
end

--- Initialize MovementTask with new data (for pool reuse)
---@param targetPosition Vec2 Final destination position
---@param requiredDistance number? Distance needed to target (default 0.5)
---@param movementSpeed number? Movement speed modifier (default 1.0)
---@return boolean Success status
function MovementTask:initialize(targetPosition, requiredDistance, movementSpeed)
  if not targetPosition or not targetPosition.x or not targetPosition.y then
    Logger:error("MovementTask:initialize - targetPosition must be a valid Vec2")
    return false
  end

  -- Initialize base TaskComponent
  local success = TaskComponent.initialize(self, targetPosition, 6, requiredDistance or 0.5, 1.0)
  if not success then
    return false
  end

  -- Initialize MovementTask-specific properties
  self.path = {}
  self.currentWaypoint = 1
  self.targetPosition = targetPosition
  self.movementSpeed = movementSpeed or 1.0
  self.totalDistance = 0

  return true
end

--- Factory method to create MovementTask from pool
---@param targetPosition Vec2 Final destination position
---@param requiredDistance number? Distance needed to target (default 0.5)
---@param movementSpeed number? Movement speed modifier (default 1.0)
---@return MovementTask?
function MovementTask.newFromPool(targetPosition, requiredDistance, movementSpeed)
  local TaskComponentPool = require("game.systems.TaskComponentPool")
  local ComponentType = require("game.utils.enums").ComponentType

  local component = TaskComponentPool:acquire(ComponentType.MOVEMENT_TASK)
  if not component then
    Logger:error("MovementTask.newFromPool - Failed to acquire component from pool")
    return nil
  end

  local success = component:initialize(targetPosition, requiredDistance, movementSpeed)
  if not success then
    TaskComponentPool:release(component, ComponentType.MOVEMENT_TASK)
    return nil
  end

  return component
end

--- Gets the component type
---@return number ComponentType enum value
function MovementTask:getComponentType()
  return require("game.utils.enums").ComponentType.MOVEMENT_TASK
end

return MovementTask
