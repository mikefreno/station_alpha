local TaskComponent = require("components.TaskComponent")
local enums = require("utils.enums")

---@class ConstructionTask : TaskComponent
---@field blueprintEntity integer What to build (entity reference)
---@field materialsRequired table Required materials map {resourceType: amount}
---@field buildProgress number 0.0 to 1.0 completion percentage
---@field constructionStage number Multi-stage construction (0-based)
---@field buildRate number Progress per second
---@field totalStages number Total construction stages
local ConstructionTask = {}
ConstructionTask.__index = ConstructionTask

--- Constructor for ConstructionTask
---@param target integer|Vec2? Target entity ID or position to construct (nil for blank constructor)
---@param blueprintEntity integer? Entity ID of the blueprint to build (nil for blank constructor)
---@param materialsRequired table? Map of {resourceType: amount} required materials (nil for blank constructor)
---@param buildRate number? Construction progress rate per second (default 0.1) (nil for blank constructor)
---@param totalStages number? Number of construction stages (default 1) (nil for blank constructor)
---@return ConstructionTask?
function ConstructionTask.new(target, blueprintEntity, materialsRequired, buildRate, totalStages)
  -- Handle blank constructor for pooling
  if not target and not blueprintEntity and not materialsRequired then
    -- Create blank TaskComponent
    local base = TaskComponent.new()
    if not base then
      return nil
    end

    -- Create ConstructionTask instance with TaskComponent as base
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

    -- Copy methods from ConstructionTask
    for k, v in pairs(ConstructionTask) do
      if type(v) == "function" and k ~= "new" then
        self[k] = v
      end
    end

    setmetatable(self, ConstructionTask)

    -- Add ConstructionTask-specific properties with defaults
    self.blueprintEntity = nil
    self.materialsRequired = {}
    self.buildProgress = 0.0
    self.constructionStage = 0
    self.buildRate = 0.1
    self.totalStages = 1

    return self
  end

  -- Regular constructor with validation
  if not target then
    Logger:error("ConstructionTask: target is required")
    return nil
  end

  if not blueprintEntity or blueprintEntity <= 0 then
    Logger:error("ConstructionTask: blueprintEntity must be a valid entity ID")
    return nil
  end

  if not materialsRequired or type(materialsRequired) ~= "table" then
    Logger:error("ConstructionTask: materialsRequired must be a table")
    return nil
  end

  -- Validate materials required format
  for resourceType, amount in pairs(materialsRequired) do
    if type(resourceType) ~= "number" or resourceType < 0 or resourceType > 12 then
      Logger:error("ConstructionTask: invalid resource type in materialsRequired")
      return nil
    end
    if type(amount) ~= "number" or amount <= 0 then
      Logger:error("ConstructionTask: material amounts must be positive numbers")
      return nil
    end
  end

  -- Calculate estimated duration based on build rate
  local stages = totalStages or 1
  local rate = buildRate or 0.1
  local duration = stages / rate

  -- Create base task component with priority 2 (high priority for construction)
  local base = TaskComponent.new(target, 2, 1.0, duration)
  if not base then
    return nil
  end

  -- Create ConstructionTask instance with TaskComponent as base
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

  setmetatable(self, ConstructionTask)

  -- Add ConstructionTask-specific properties
  self.blueprintEntity = blueprintEntity
  self.materialsRequired = materialsRequired
  self.buildProgress = 0.0
  self.constructionStage = 0
  self.buildRate = rate
  self.totalStages = stages

  return self
end

--- Updates construction progress (call this each frame)
---@param dt number Delta time in seconds
---@return boolean True if still building, false if complete
function ConstructionTask:updateProgress(dt)
  if self.isComplete then
    return false
  end

  -- Add progress based on build rate
  self.buildProgress = self.buildProgress + (self.buildRate * dt)

  -- Check for stage completion
  local stageProgress = 1.0 / self.totalStages
  local expectedStage = math.floor(self.buildProgress / stageProgress)

  if expectedStage > self.constructionStage and expectedStage < self.totalStages then
    self.constructionStage = expectedStage
    -- Could trigger stage-specific events here
  end

  -- Check if construction is complete
  if self.buildProgress >= 1.0 then
    self.buildProgress = 1.0
    self.constructionStage = self.totalStages - 1
    self:markComplete()
    return false
  end

  return true
end

--- Checks if entity can perform this construction task
---@param entity table Entity to check (should have required materials)
---@return boolean True if entity can perform construction
function ConstructionTask:canPerform(entity)
  if not entity then
    return false
  end

  -- TODO: Check if entity has required materials when inventory system is implemented
  -- For now, assume entity can perform if valid

  return true
end

--- Gets construction progress (0.0 to 1.0)
---@return number Progress percentage
function ConstructionTask:getProgress()
  if self.isComplete then
    return 1.0
  end

  return math.min(self.buildProgress, 1.0)
end

--- Gets remaining work time estimate
---@return number Estimated seconds remaining
function ConstructionTask:getRemainingWork()
  if self.isComplete then
    return 0
  end

  local remainingProgress = 1.0 - self.buildProgress
  return remainingProgress / self.buildRate
end

--- Advances to the next construction stage
---@return boolean True if advanced, false if already at final stage
function ConstructionTask:advanceStage()
  if self.constructionStage < self.totalStages - 1 then
    self.constructionStage = self.constructionStage + 1
    return true
  end
  return false
end

--- Checks if materials are available for construction
---@param availableMaterials table Map of {resourceType: amount} available
---@return boolean True if all required materials are available
function ConstructionTask:hasSufficientMaterials(availableMaterials)
  if not availableMaterials then
    return false
  end

  for resourceType, requiredAmount in pairs(self.materialsRequired) do
    local availableAmount = availableMaterials[resourceType] or 0
    if availableAmount < requiredAmount then
      return false
    end
  end

  return true
end

--- Gets the blueprint entity ID
---@return integer Blueprint entity ID
function ConstructionTask:getBlueprintEntity()
  return self.blueprintEntity
end

--- Gets the current construction stage
---@return number Current stage (0-based)
function ConstructionTask:getCurrentStage()
  return self.constructionStage
end

--- Gets required materials table
---@return table Materials required {resourceType: amount}
function ConstructionTask:getRequiredMaterials()
  return self.materialsRequired
end

--- Creates a string representation for debugging
---@return string Debug string
function ConstructionTask:toString()
  return string.format(
    "ConstructionTask{blueprint=%d, stage=%d/%d, progress=%.1f%%, complete=%s}",
    self.blueprintEntity,
    self.constructionStage + 1,
    self.totalStages,
    self.buildProgress * 100,
    tostring(self.isComplete)
  )
end

--- Reset component state for object pooling
function ConstructionTask:reset()
  -- Reset base TaskComponent properties
  TaskComponent.reset(self)

  -- Reset ConstructionTask-specific properties
  self.blueprintEntity = nil
  self.materialsRequired = {}
  self.buildRate = 1.0
  self.totalStages = 1
  self.constructionStage = 0
  self.buildProgress = 0.0
end

--- Initialize ConstructionTask with new data (for pool reuse)
---@param target integer|Vec2 What to construct (entity ID or position)
---@param blueprintEntity integer Blueprint entity ID
---@param materialsRequired table Materials needed {resourceType: amount}
---@param buildRate number? Building rate modifier (default 1.0)
---@param totalStages number? Number of construction stages (default 1)
---@return boolean Success status
function ConstructionTask:initialize(target, blueprintEntity, materialsRequired, buildRate, totalStages)
  if not blueprintEntity then
    Logger:error("ConstructionTask:initialize - blueprintEntity is required")
    return false
  end

  if not materialsRequired or type(materialsRequired) ~= "table" then
    Logger:error("ConstructionTask:initialize - materialsRequired must be a table")
    return false
  end

  -- Calculate estimated duration based on stages and build rate
  local stageCount = totalStages or 1
  local estimatedDuration = stageCount * (1.0 / (buildRate or 1.0))

  -- Initialize base TaskComponent
  local success = TaskComponent.initialize(self, target, 2, 1.0, estimatedDuration)
  if not success then
    return false
  end

  -- Initialize ConstructionTask-specific properties
  self.blueprintEntity = blueprintEntity
  self.materialsRequired = materialsRequired
  self.buildRate = buildRate or 1.0
  self.totalStages = stageCount
  self.constructionStage = 0
  self.buildProgress = 0.0

  return true
end

--- Factory method to create ConstructionTask from pool
---@param target integer|Vec2 What to construct (entity ID or position)
---@param blueprintEntity integer Blueprint entity ID
---@param materialsRequired table Materials needed {resourceType: amount}
---@param buildRate number? Building rate modifier (default 1.0)
---@param totalStages number? Number of construction stages (default 1)
---@return ConstructionTask?
function ConstructionTask.newFromPool(target, blueprintEntity, materialsRequired, buildRate, totalStages)
  local TaskComponentPool = require("game.systems.TaskComponentPool")
  local ComponentType = require("game.utils.enums").ComponentType

  local component = TaskComponentPool:acquire(ComponentType.CONSTRUCTION_TASK)
  if not component then
    Logger:error("ConstructionTask.newFromPool - Failed to acquire component from pool")
    return nil
  end

  local success = component:initialize(target, blueprintEntity, materialsRequired, buildRate, totalStages)
  if not success then
    TaskComponentPool:release(component, ComponentType.CONSTRUCTION_TASK)
    return nil
  end

  return component
end

--- Gets the component type
---@return number ComponentType enum value
function ConstructionTask:getComponentType()
  return require("game.utils.enums").ComponentType.CONSTRUCTION_TASK
end

return ConstructionTask
