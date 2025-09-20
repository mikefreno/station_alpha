local TaskComponent = require("components.TaskComponent")
local enums = require("utils.enums")

---@class CleaningTask : TaskComponent
---@field cleaningRadius number Area of effect (in tiles)
---@field dirtEntities integer[] Entities to clean (list of dirty objects)
---@field cleaningTool number Required cleaning implement (ToolType enum)
---@field cleaningRate number Cleaning units per second
---@field totalDirtiness number Total dirtiness to clean
---@field cleanedDirtiness number Amount of dirtiness already cleaned
local CleaningTask = {}
CleaningTask.__index = CleaningTask

--- Constructor for CleaningTask
---@param target integer|Vec2? Target entity ID or position to clean (nil for blank constructor)
---@param cleaningRadius number? Area of effect in tiles (default 1.0) (nil for blank constructor)
---@param cleaningTool number? Required cleaning tool (ToolType enum) (nil for blank constructor)
---@param cleaningRate number? Cleaning units per second (default 0.5) (nil for blank constructor)
---@param totalDirtiness number? Total dirtiness amount to clean (default 10.0) (nil for blank constructor)
---@return CleaningTask?
function CleaningTask.new(target, cleaningRadius, cleaningTool, cleaningRate, totalDirtiness)
  -- Handle blank constructor for pooling
  if not target and not cleaningRadius and not cleaningTool then
    -- Create blank TaskComponent
    local base = TaskComponent.new()
    if not base then
      return nil
    end

    -- Create CleaningTask instance with TaskComponent as base
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

    -- Copy methods from CleaningTask
    for k, v in pairs(CleaningTask) do
      if type(v) == "function" and k ~= "new" then
        self[k] = v
      end
    end

    setmetatable(self, CleaningTask)

    -- Add CleaningTask-specific properties with defaults
    self.cleaningRadius = 1.0
    self.dirtEntities = {}
    self.cleaningTool = 0
    self.cleaningRate = 0.5
    self.totalDirtiness = 10.0
    self.cleanedDirtiness = 0

    return self
  end

  -- Regular constructor with validation
  if not target then
    Logger:error("CleaningTask: target is required")
    return nil
  end

  if not cleaningRadius or cleaningRadius <= 0 then
    Logger:error("CleaningTask: cleaningRadius must be positive")
    return nil
  end

  if not cleaningTool or cleaningTool < 0 or cleaningTool > 9 then
    Logger:error("CleaningTask: cleaningTool must be a valid ToolType")
    return nil
  end

  local rate = cleaningRate or 0.5
  local dirtiness = totalDirtiness or 10.0

  if rate <= 0 or dirtiness <= 0 then
    Logger:error("CleaningTask: cleaningRate and totalDirtiness must be positive")
    return nil
  end

  -- Calculate estimated duration based on cleaning rate
  local duration = dirtiness / rate

  -- Create base task component with priority 1 (lower priority for cleaning)
  local base = TaskComponent.new(target, 1, cleaningRadius, duration)
  if not base then
    return nil
  end

  -- Create CleaningTask instance with TaskComponent as base
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

  setmetatable(self, CleaningTask)

  -- Add CleaningTask-specific properties
  self.cleaningRadius = cleaningRadius
  self.dirtEntities = {}
  self.cleaningTool = cleaningTool
  self.cleaningRate = rate
  self.totalDirtiness = dirtiness
  self.cleanedDirtiness = 0

  return self
end

--- Updates cleaning progress (call this each frame)
---@param dt number Delta time in seconds
---@return boolean True if still cleaning, false if complete
function CleaningTask:updateProgress(dt)
  if self.isComplete then
    return false
  end

  -- Add progress based on cleaning rate
  self.cleanedDirtiness = self.cleanedDirtiness + (self.cleaningRate * dt)

  -- Check if cleaning is complete
  if self.cleanedDirtiness >= self.totalDirtiness then
    self.cleanedDirtiness = self.totalDirtiness
    self:markComplete()
    return false
  end

  return true
end

--- Checks if entity can perform this cleaning task
---@param entity table Entity to check (should have required cleaning tool)
---@return boolean True if entity can perform cleaning
function CleaningTask:canPerform(entity)
  if not entity then
    return false
  end

  -- TODO: Check if entity has required cleaning tool when tool system is implemented
  -- For now, assume entity can perform if valid

  return true
end

--- Gets cleaning progress (0.0 to 1.0)
---@return number Progress percentage
function CleaningTask:getProgress()
  if self.isComplete then
    return 1.0
  end

  if self.totalDirtiness <= 0 then
    return 0.0
  end

  return math.min(self.cleanedDirtiness / self.totalDirtiness, 1.0)
end

--- Gets remaining work time estimate
---@return number Estimated seconds remaining
function CleaningTask:getRemainingWork()
  if self.isComplete then
    return 0
  end

  local remainingDirtiness = self.totalDirtiness - self.cleanedDirtiness
  return remainingDirtiness / self.cleaningRate
end

--- Adds a dirty entity to the cleaning list
---@param entityId integer Entity ID to add to cleaning list
function CleaningTask:addDirtyEntity(entityId)
  if entityId and entityId > 0 then
    table.insert(self.dirtEntities, entityId)
  end
end

--- Removes a dirty entity from the cleaning list
---@param entityId integer Entity ID to remove from cleaning list
---@return boolean True if entity was found and removed
function CleaningTask:removeDirtyEntity(entityId)
  for i, id in ipairs(self.dirtEntities) do
    if id == entityId then
      table.remove(self.dirtEntities, i)
      return true
    end
  end
  return false
end

--- Gets the number of dirty entities
---@return integer Number of entities to clean
function CleaningTask:getDirtyEntityCount()
  return #self.dirtEntities
end

--- Checks if an entity is in the dirty entities list
---@param entityId integer Entity ID to check
---@return boolean True if entity is in the list
function CleaningTask:hasDirtyEntity(entityId)
  for _, id in ipairs(self.dirtEntities) do
    if id == entityId then
      return true
    end
  end
  return false
end

--- Gets the cleaning radius
---@return number Cleaning radius in tiles
function CleaningTask:getCleaningRadius()
  return self.cleaningRadius
end

--- Gets the required cleaning tool
---@return number ToolType enum value
function CleaningTask:getRequiredTool()
  return self.cleaningTool
end

--- Gets the cleaning rate
---@return number Cleaning units per second
function CleaningTask:getCleaningRate()
  return self.cleaningRate
end

--- Gets remaining dirtiness to clean
---@return number Remaining dirtiness amount
function CleaningTask:getRemainingDirtiness()
  return math.max(0, self.totalDirtiness - self.cleanedDirtiness)
end

--- Creates a string representation for debugging
---@return string Debug string
function CleaningTask:toString()
  return string.format(
    "CleaningTask{tool=%d, radius=%.1f, cleaned=%.1f/%.1f, entities=%d, complete=%s}",
    self.cleaningTool,
    self.cleaningRadius,
    self.cleanedDirtiness,
    self.totalDirtiness,
    #self.dirtEntities,
    tostring(self.isComplete)
  )
end

--- Reset component state for object pooling
function CleaningTask:reset()
  -- Reset base TaskComponent properties
  TaskComponent.reset(self)

  -- Reset CleaningTask-specific properties
  self.cleaningRadius = 1.0
  self.cleaningTool = 0 -- ToolType.NONE
  self.cleaningRate = 1.0
  self.totalDirtiness = 1.0
  self.cleanedDirtiness = 0.0
  self.dirtEntities = {}
end

--- Initialize CleaningTask with new data (for pool reuse)
---@param target integer|Vec2 What to clean (entity ID or position)
---@param cleaningRadius number Radius of cleaning area
---@param cleaningTool number ToolType enum value required
---@param cleaningRate number? Cleaning rate per second (default 1.0)
---@param totalDirtiness number? Total dirtiness to clean (default 1.0)
---@return boolean Success status
function CleaningTask:initialize(target, cleaningRadius, cleaningTool, cleaningRate, totalDirtiness)
  if not cleaningRadius or cleaningRadius <= 0 then
    Logger:error("CleaningTask:initialize - cleaningRadius must be > 0")
    return false
  end

  if not cleaningTool then
    Logger:error("CleaningTask:initialize - cleaningTool is required")
    return false
  end

  -- Calculate estimated duration
  local dirtAmount = totalDirtiness or 1.0
  local cleanRate = cleaningRate or 1.0
  local estimatedDuration = dirtAmount / cleanRate

  -- Initialize base TaskComponent
  local success = TaskComponent.initialize(self, target, 1, cleaningRadius, estimatedDuration)
  if not success then
    return false
  end

  -- Initialize CleaningTask-specific properties
  self.cleaningRadius = cleaningRadius
  self.cleaningTool = cleaningTool
  self.cleaningRate = cleanRate
  self.totalDirtiness = dirtAmount
  self.cleanedDirtiness = 0.0
  self.dirtEntities = {}

  return true
end

--- Factory method to create CleaningTask from pool
---@param target integer|Vec2 What to clean (entity ID or position)
---@param cleaningRadius number Radius of cleaning area
---@param cleaningTool number ToolType enum value required
---@param cleaningRate number? Cleaning rate per second (default 1.0)
---@param totalDirtiness number? Total dirtiness to clean (default 1.0)
---@return CleaningTask?
function CleaningTask.newFromPool(target, cleaningRadius, cleaningTool, cleaningRate, totalDirtiness)
  local TaskComponentPool = require("game.systems.TaskComponentPool")
  local ComponentType = require("game.utils.enums").ComponentType

  local component = TaskComponentPool:acquire(ComponentType.CLEANING_TASK)
  if not component then
    Logger:error("CleaningTask.newFromPool - Failed to acquire component from pool")
    return nil
  end

  local success = component:initialize(target, cleaningRadius, cleaningTool, cleaningRate, totalDirtiness)
  if not success then
    TaskComponentPool:release(component, ComponentType.CLEANING_TASK)
    return nil
  end

  return component
end

--- Gets the component type
---@return number ComponentType enum value
function CleaningTask:getComponentType()
  return require("game.utils.enums").ComponentType.CLEANING_TASK
end

return CleaningTask
