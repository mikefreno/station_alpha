local TaskComponent = require("components.TaskComponent")
local enums = require("utils.enums")

---@class MiningTask : TaskComponent
---@field swingTimer number Time until next swing (countdown)
---@field swingsRemaining number Swings needed to complete
---@field toolRequired number Required tool type (from ToolType enum)
---@field yieldType number What resource this produces (from ResourceType enum)
---@field swingDuration number Time per swing (default 1.0 seconds)
---@field totalSwings number Total swings needed (for progress calculation)
local MiningTask = {}
MiningTask.__index = MiningTask

--- Constructor for MiningTask
---@param target integer|Vec2? Target entity ID or position to mine (nil for blank constructor)
---@param swingsRequired number? Number of swings needed to complete mining (nil for blank constructor)
---@param toolRequired number? Required tool type (ToolType enum) (nil for blank constructor)
---@param yieldType number? Resource type that will be produced (ResourceType enum) (nil for blank constructor)
---@param swingDuration number? Time per swing in seconds (default 1.0) (nil for blank constructor)
---@return MiningTask?
function MiningTask.new(target, swingsRequired, toolRequired, yieldType, swingDuration)
  -- Handle blank constructor for pooling
  if not target and not swingsRequired and not toolRequired and not yieldType then
    -- Create blank TaskComponent
    local base = TaskComponent.new()
    if not base then
      return nil
    end

    -- Create MiningTask instance with TaskComponent as base
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

    -- Copy methods from MiningTask
    for k, v in pairs(MiningTask) do
      if type(v) == "function" and k ~= "new" then
        self[k] = v
      end
    end

    setmetatable(self, MiningTask)

    -- Add MiningTask-specific properties with defaults
    self.swingTimer = 0
    self.swingsRemaining = 1
    self.toolRequired = 0
    self.yieldType = 0
    self.swingDuration = 1.0
    self.totalSwings = 1

    return self
  end

  -- Regular constructor with validation
  if not target then
    Logger:error("MiningTask: target is required")
    return nil
  end

  if not swingsRequired or swingsRequired <= 0 then
    Logger:error("MiningTask: swingsRequired must be positive")
    return nil
  end

  if not toolRequired or toolRequired < 0 or toolRequired > 9 then
    Logger:error("MiningTask: toolRequired must be a valid ToolType")
    return nil
  end

  if not yieldType or yieldType < 0 or yieldType > 12 then
    Logger:error("MiningTask: yieldType must be a valid ResourceType")
    return nil
  end

  -- Create base task component with priority 3 and estimated duration
  local duration = (swingDuration or 1.0) * swingsRequired
  local base = TaskComponent.new(target, 3, 1.0, duration)
  if not base then
    return nil
  end

  -- Create MiningTask instance with TaskComponent as base
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

  setmetatable(self, MiningTask)

  -- Add MiningTask-specific properties
  self.swingTimer = 0
  self.swingsRemaining = swingsRequired
  self.toolRequired = toolRequired
  self.yieldType = yieldType
  self.swingDuration = swingDuration or 1.0
  self.totalSwings = swingsRequired

  return self
end

--- Updates mining progress (call this each frame)
---@param dt number Delta time in seconds
---@return boolean True if still mining, false if complete
function MiningTask:updateProgress(dt)
  if self.isComplete then
    return false
  end

  -- Only process swing timing if a swing is active
  if self.swingTimer > 0 then
    self.swingTimer = self.swingTimer - dt
    
    -- Check if swing just completed
    if self.swingTimer <= 0 then
      self.swingsRemaining = self.swingsRemaining - 1
      self.swingTimer = 0 -- Reset to 0, ready for next swing

      -- Check if mining is complete
      if self.swingsRemaining <= 0 then
        self:markComplete()
        return false
      end
    end
  end

  return true
end

--- Checks if entity can perform this mining task
---@param entity table Entity to check (should have tool components)
---@return boolean True if entity can mine with required tool
function MiningTask:canExecute(entity)
  -- Verify entity has required tool
  local toolComponent = EntityManager:getComponent(entity, enums.ComponentType.TOOL)
  return toolComponent and toolComponent.toolType == self.toolRequired
end

--- Starts the next swing (call when ready to swing)
---@return boolean True if swing started, false if already swinging or complete
function MiningTask:startSwing()
  if self.isComplete or self.swingTimer > 0 then
    return false
  end

  self.swingTimer = self.swingDuration
  return true
end

--- Gets remaining time for current swing
---@return number Time in seconds until swing completes (0 if not swinging)
function MiningTask:getRemainingSwingTime()
  return math.max(0, self.swingTimer)
end

--- Gets total estimated time remaining
---@return number Time in seconds for all remaining swings
function MiningTask:getEstimatedTimeRemaining()
  if self.isComplete then
    return 0
  end
  
  return self.swingTimer + (self.swingsRemaining - 1) * self.swingDuration
end

--- Checks if currently swinging
---@return boolean True if a swing is in progress
function MiningTask:isSwinging()
  return self.swingTimer > 0 and not self.isComplete
end

--- Gets required tool type
---@return number ToolType enum value
function MiningTask:getRequiredTool()
  return self.toolRequired
end

--- Gets yield type that will be produced
---@return number ResourceType enum value
function MiningTask:getYieldType()
  return self.yieldType
end

--- Reset component state for object pooling
function MiningTask:reset()
  -- Reset base TaskComponent properties
  TaskComponent.reset(self)

  -- Reset MiningTask-specific properties
  self.swingsRequired = 1
  self.swingsRemaining = 1
  self.totalSwings = 1
  self.toolRequired = 0 -- ToolType.NONE
  self.yieldType = 0 -- ResourceType.NONE
  self.swingDuration = 1.0
  self.swingTimer = 0
end

--- Initialize MiningTask with new data (for pool reuse)
---@param target integer|Vec2 What to mine (entity ID or position)
---@param swingsRequired number Number of swings needed
---@param toolRequired number ToolType enum value required
---@param yieldType number ResourceType enum value produced
---@param swingDuration number? Time per swing in seconds (default 1.0)
---@return boolean True if initialization successful
function MiningTask:initialize(target, swingsRequired, toolRequired, yieldType, swingDuration)
  -- Validate parameters (same as constructor)
  if not target then
    Logger:error("MiningTask:initialize - target is required")
    return false
  end

  if not swingsRequired or swingsRequired <= 0 then
    Logger:error("MiningTask:initialize - swingsRequired must be positive")
    return false
  end

  if not toolRequired or toolRequired < 0 or toolRequired > 9 then
    Logger:error("MiningTask:initialize - toolRequired must be a valid ToolType")
    return false
  end

  if not yieldType or yieldType < 0 or yieldType > 12 then
    Logger:error("MiningTask:initialize - yieldType must be a valid ResourceType")
    return false
  end

  -- Initialize base TaskComponent
  local duration = (swingDuration or 1.0) * swingsRequired
  if not TaskComponent.initialize(self, target, 3, 1.0, duration) then
    return false
  end

  -- Initialize MiningTask-specific properties
  self.swingTimer = 0
  self.swingsRemaining = swingsRequired
  self.toolRequired = toolRequired
  self.yieldType = yieldType
  self.swingDuration = swingDuration or 1.0
  self.totalSwings = swingsRequired

  return true
end

--- Checks if component is ready for pooling
---@return boolean True if component can be safely pooled
function MiningTask:isPoolable()
  return true
end

--- Factory method to create MiningTask from pool
---@param target integer|Vec2 What to mine (entity ID or position)
---@param swingsRequired number Number of swings needed
---@param toolRequired number ToolType enum value required
---@param yieldType number ResourceType enum value produced
---@param swingDuration number? Time per swing in seconds (default 1.0)
---@return MiningTask?
function MiningTask.newFromPool(target, swingsRequired, toolRequired, yieldType, swingDuration)
  local TaskComponentPool = require("systems.TaskComponentPool")
  local ComponentType = require("utils.enums").ComponentType
  
  local component = TaskComponentPool:acquire(ComponentType.MINING_TASK)
  if component then
    if component:initialize(target, swingsRequired, toolRequired, yieldType, swingDuration) then
      return component
    else
      -- Failed to initialize, return to pool
      TaskComponentPool:release(component, ComponentType.MINING_TASK)
      return nil
    end
  end
  
  -- Pool exhausted, create new instance
  return MiningTask.new(target, swingsRequired, toolRequired, yieldType, swingDuration)
end

--- Get mining progress as percentage
---@return number Progress from 0.0 to 1.0
function MiningTask:getProgress()
  if self.isComplete then
    return 1.0
  end

  local completedSwings = self.totalSwings - self.swingsRemaining
  local currentSwingProgress = 0
  
  if self.swingTimer > 0 then
    currentSwingProgress = 1.0 - (self.swingTimer / self.swingDuration)
  end

  return math.min(1.0, (completedSwings + currentSwingProgress) / self.totalSwings)
end

--- String representation for debugging
---@return string Human-readable description
function MiningTask:toString()
  return string.format(
    "MiningTask(target=%s, swings=%d/%d, tool=%d, yield=%d, complete=%s)",
    tostring(self.target),
    self.totalSwings - self.swingsRemaining,
    self.totalSwings,
    self.toolRequired,
    self.yieldType,
    tostring(self.isComplete)
  )
end

--- Gets the component type
---@return number ComponentType enum value
function MiningTask:getComponentType()
  return require("game.utils.enums").ComponentType.MINING_TASK
end

return MiningTask