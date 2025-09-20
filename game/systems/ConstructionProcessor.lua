local ComponentType = require("game.utils.enums").ComponentType
local Logger = require("logger")
local PerformanceMonitor = require("game.systems.PerformanceMonitor")

---@class ConstructionProcessor
---@field defaultBuildRate number Progress per second
---@field processedEntities number Statistics: entities processed this frame
---@field completedTasks number Statistics: tasks completed this frame
---@field buildingsCompleted number Statistics: buildings completed this frame
---@field performanceMonitor PerformanceMonitor Performance tracking system
local ConstructionProcessor = {}
ConstructionProcessor.__index = ConstructionProcessor

--- Creates a new ConstructionProcessor instance
---@return ConstructionProcessor
function ConstructionProcessor.new()
  local self = setmetatable({}, ConstructionProcessor)

  self.defaultBuildRate = 0.1
  self.processedEntities = 0
  self.completedTasks = 0
  self.buildingsCompleted = 0
  
  -- Initialize performance monitoring
  self.performanceMonitor = PerformanceMonitor
  if not self.performanceMonitor.isInitialized then
    self.performanceMonitor:init()
  end

  return self
end

--- Batch processes all entities with ConstructionTask components
---@param entities number[] Array of entity IDs with construction tasks
---@param dt number Delta time for this frame
function ConstructionProcessor:processBatch(entities, dt)
  if not entities or #entities == 0 then
    return
  end

  -- Start performance monitoring
  local batchStartTime = love.timer.getTime()

  self.processedEntities = 0
  self.completedTasks = 0
  self.buildingsCompleted = 0

  for _, entityId in ipairs(entities) do
    local constructionTask = EntityManager:getComponent(entityId, ComponentType.CONSTRUCTION_TASK)
    if constructionTask and not constructionTask.isComplete then
      local wasCompleted = self:processConstruction(entityId, constructionTask, dt)
      self.processedEntities = self.processedEntities + 1

      if wasCompleted then
        self.completedTasks = self.completedTasks + 1
      end
    end
  end
  
  -- Record performance metrics
  local batchTime = love.timer.getTime() - batchStartTime
  self.performanceMonitor:recordSystemMetrics("ConstructionProcessor", batchTime, #entities)
  self.performanceMonitor:recordTaskMetrics(ComponentType.CONSTRUCTION_TASK, batchTime, self.processedEntities, #entities)
end

--- Processes construction for a single entity
---@param entityId number Entity ID
---@param constructionTask ConstructionTask Construction task component
---@param dt number Delta time
---@return boolean True if task was completed
function ConstructionProcessor:processConstruction(entityId, constructionTask, dt)
  -- Check if entity has required materials and tools
  if not self:checkRequirements(entityId, constructionTask) then
    Logger:debug("ConstructionProcessor: Entity " .. entityId .. " lacks required materials or tools")
    return false
  end

  -- Check if construction site is still valid
  if not self:isValidSite(constructionTask.target) then
    Logger:debug("ConstructionProcessor: Invalid construction site for entity " .. entityId)
    constructionTask:markComplete()
    return true
  end

  -- Update construction progress
  local completed = self:updateProgress(constructionTask, dt)
  if completed then
    self:handleCompletion(entityId, constructionTask)
    self.buildingsCompleted = self.buildingsCompleted + 1
    return true
  end

  return false
end

--- Updates construction progress
---@param constructionTask ConstructionTask Construction task component
---@param dt number Delta time
---@return boolean True if construction is complete
function ConstructionProcessor:updateProgress(constructionTask, dt)
  -- Calculate build rate
  local buildRate = constructionTask.buildRate or self.defaultBuildRate

  -- Update progress
  local progressIncrement = buildRate * dt
  constructionTask.progress = (constructionTask.progress or 0) + progressIncrement

  -- Check if construction is complete
  if constructionTask.progress >= 1.0 then
    constructionTask.progress = 1.0
    constructionTask:markComplete()
    return true
  end

  return false
end

--- Checks if entity has required materials and tools for construction
---@param entityId number Entity ID
---@param constructionTask ConstructionTask Construction task component
---@return boolean True if requirements are met
function ConstructionProcessor:checkRequirements(entityId, constructionTask)
  -- Check required materials
  if constructionTask.requiredMaterials then
    local inventory = EntityManager:getComponent(entityId, ComponentType.INVENTORY)
    if not inventory then
      return false
    end

    for materialType, requiredAmount in pairs(constructionTask.requiredMaterials) do
      local availableAmount = inventory.items[materialType] or 0
      if availableAmount < requiredAmount then
        return false
      end
    end
  end

  -- Check for required tool if specified
  if constructionTask.requiredTool then
    local tool = EntityManager:getComponent(entityId, ComponentType.TOOL)
    if not tool or tool.type ~= constructionTask.requiredTool then
      return false
    end

    -- Check tool durability
    if tool.durability and tool.durability <= 0 then
      return false
    end
  end

  -- Check for required skill level
  if constructionTask.requiredSkillLevel then
    local skills = EntityManager:getComponent(entityId, ComponentType.SKILLS)
    if not skills or not skills.construction or skills.construction < constructionTask.requiredSkillLevel then
      return false
    end
  end

  return true
end

--- Checks if construction site is valid
---@param targetId number Target entity ID
---@return boolean True if site is valid for construction
function ConstructionProcessor:isValidSite(targetId)
  if not targetId then
    return false
  end

  -- Check if target still exists
  local buildable = EntityManager:getComponent(targetId, ComponentType.BUILDABLE)
  return buildable ~= nil
end

--- Consumes materials from entity's inventory
---@param entityId number Entity ID
---@param constructionTask ConstructionTask Construction task component
function ConstructionProcessor:consumeMaterials(entityId, constructionTask)
  if not constructionTask.requiredMaterials then
    return
  end

  local inventory = EntityManager:getComponent(entityId, ComponentType.INVENTORY)
  if not inventory then
    return
  end

  for materialType, requiredAmount in pairs(constructionTask.requiredMaterials) do
    local availableAmount = inventory.items[materialType] or 0
    if availableAmount >= requiredAmount then
      inventory.items[materialType] = availableAmount - requiredAmount
      Logger:debug("ConstructionProcessor: Consumed " .. requiredAmount .. " " .. materialType)
    end
  end
end

--- Creates the constructed building
---@param constructionTask ConstructionTask Completed construction task
function ConstructionProcessor:createBuilding(constructionTask)
  local buildable = EntityManager:getComponent(constructionTask.target, ComponentType.BUILDABLE)
  if not buildable then
    return
  end

  -- Get building position
  local position = EntityManager:getComponent(constructionTask.target, ComponentType.POSITION)
  if not position then
    return
  end

  -- Create new building entity
  local buildingEntityId = EntityManager:createEntity()
  
  -- Add building components
  EntityManager:addComponent(buildingEntityId, ComponentType.POSITION, {
    x = position.x,
    y = position.y
  })

  -- Add building-specific components
  if buildable.buildingType then
    EntityManager:addComponent(buildingEntityId, ComponentType.BUILDING, {
      type = buildable.buildingType,
      health = buildable.maxHealth or 100,
      maxHealth = buildable.maxHealth or 100
    })
  end

  -- Add any additional components specified in buildable
  if buildable.components then
    for componentType, componentData in pairs(buildable.components) do
      EntityManager:addComponent(buildingEntityId, componentType, componentData)
    end
  end

  Logger:debug("ConstructionProcessor: Created building " .. buildingEntityId .. " at (" .. position.x .. "," .. position.y .. ")")

  return buildingEntityId
end

--- Removes the construction site
---@param targetId number Target entity ID
function ConstructionProcessor:removeConstructionSite(targetId)
  -- Remove the construction site entity
  if EntityManager.removeEntity then
    EntityManager:removeEntity(targetId)
  else
    -- Fallback: remove buildable component
    EntityManager:removeComponent(targetId, ComponentType.BUILDABLE)
  end

  Logger:debug("ConstructionProcessor: Removed construction site " .. targetId)
end

--- Handles construction task completion
---@param entityId number Entity ID
---@param constructionTask ConstructionTask Completed construction task
function ConstructionProcessor:handleCompletion(entityId, constructionTask)
  -- Consume materials
  self:consumeMaterials(entityId, constructionTask)

  -- Create the building
  self:createBuilding(constructionTask)

  -- Remove construction site
  self:removeConstructionSite(constructionTask.target)

  -- Remove the ConstructionTask component
  EntityManager:removeComponent(entityId, ComponentType.CONSTRUCTION_TASK)

  -- Return task component to pool if it's poolable
  if constructionTask._poolable then
    local TaskComponentPool = require("game.systems.TaskComponentPool")
    TaskComponentPool:release(constructionTask, ComponentType.CONSTRUCTION_TASK)
  end

  Logger:debug("ConstructionProcessor: Completed construction task for entity " .. entityId)
end

--- Gets performance statistics for the last update
---@return table Performance stats
function ConstructionProcessor:getStats()
  return {
    processedEntities = self.processedEntities,
    completedTasks = self.completedTasks,
    buildingsCompleted = self.buildingsCompleted
  }
end

--- Process method for TaskExecutionSystem integration
---@param entityId number Entity ID to process
---@param constructionTask ConstructionTask Construction task component
---@param dt number Delta time
---@return boolean Success status
function ConstructionProcessor:process(entityId, constructionTask, dt)
  if not constructionTask or constructionTask.isComplete then
    return true
  end

  local wasCompleted = self:processConstruction(entityId, constructionTask, dt)
  return true
end

--- Registers this processor with TaskExecutionSystem
---@param taskExecutionSystem TaskExecutionSystem The system to register with
---@return boolean Success status
function ConstructionProcessor:registerWithTaskExecutionSystem(taskExecutionSystem)
  if not taskExecutionSystem then
    Logger:error("ConstructionProcessor: Invalid TaskExecutionSystem provided")
    return false
  end

  local success = taskExecutionSystem:registerProcessor(ComponentType.CONSTRUCTION_TASK, self)
  if success then
    Logger:info("ConstructionProcessor: Successfully registered with TaskExecutionSystem")
  else
    Logger:error("ConstructionProcessor: Failed to register with TaskExecutionSystem")
  end

  return success
end

return ConstructionProcessor