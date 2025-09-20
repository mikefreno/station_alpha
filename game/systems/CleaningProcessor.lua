local ComponentType = require("game.utils.enums").ComponentType
local Vec2 = require("game.utils.Vec2")
local Logger = require("logger")
local PerformanceMonitor = require("game.systems.PerformanceMonitor")

---@class CleaningProcessor
---@field defaultCleaningRate number Dirtiness units per second
---@field processedEntities number Statistics: entities processed this frame
---@field completedTasks number Statistics: tasks completed this frame
---@field areasCleanedCount number Statistics: areas cleaned this frame
---@field performanceMonitor PerformanceMonitor Performance tracking system
local CleaningProcessor = {}
CleaningProcessor.__index = CleaningProcessor

--- Creates a new CleaningProcessor instance
---@return CleaningProcessor
function CleaningProcessor.new()
  local self = setmetatable({}, CleaningProcessor)

  self.defaultCleaningRate = 2.0
  self.processedEntities = 0
  self.completedTasks = 0
  self.areasCleanedCount = 0
  
  -- Initialize performance monitoring
  self.performanceMonitor = PerformanceMonitor
  if not self.performanceMonitor.isInitialized then
    self.performanceMonitor:init()
  end

  return self
end

--- Batch processes all entities with CleaningTask components
---@param entities number[] Array of entity IDs with cleaning tasks
---@param dt number Delta time for this frame
function CleaningProcessor:processBatch(entities, dt)
  if not entities or #entities == 0 then
    return
  end

  -- Start performance monitoring
  local batchStartTime = love.timer.getTime()

  self.processedEntities = 0
  self.completedTasks = 0
  self.areasCleanedCount = 0

  for _, entityId in ipairs(entities) do
    local cleaningTask = EntityManager:getComponent(entityId, ComponentType.CLEANING_TASK)
    if cleaningTask and not cleaningTask.isComplete then
      local wasCompleted = self:processCleaning(entityId, cleaningTask, dt)
      self.processedEntities = self.processedEntities + 1

      if wasCompleted then
        self.completedTasks = self.completedTasks + 1
      end
    end
  end
  
  -- Record performance metrics
  local batchTime = love.timer.getTime() - batchStartTime
  self.performanceMonitor:recordSystemMetrics("CleaningProcessor", batchTime, #entities)
  self.performanceMonitor:recordTaskMetrics(ComponentType.CLEANING_TASK, batchTime, self.processedEntities, #entities)
end

--- Processes cleaning for a single entity
---@param entityId number Entity ID
---@param cleaningTask CleaningTask Cleaning task component
---@param dt number Delta time
---@return boolean True if task was completed
function CleaningProcessor:processCleaning(entityId, cleaningTask, dt)
  -- Check if entity has required tools
  if not self:checkRequirements(entityId, cleaningTask) then
    Logger:debug("CleaningProcessor: Entity " .. entityId .. " lacks required tools for cleaning")
    return false
  end

  -- Check if cleaning area is still valid
  if not self:isValidArea(cleaningTask.targetPosition, cleaningTask.radius) then
    Logger:debug("CleaningProcessor: Invalid cleaning area for entity " .. entityId)
    cleaningTask:markComplete()
    return true
  end

  -- Process cleaning in the area
  local completed = self:performCleaning(entityId, cleaningTask, dt)
  if completed then
    self:handleCompletion(entityId, cleaningTask)
    self.areasCleanedCount = self.areasCleanedCount + 1
    return true
  end

  return false
end

--- Performs the actual cleaning process
---@param entityId number Entity ID
---@param cleaningTask CleaningTask Cleaning task component
---@param dt number Delta time
---@return boolean True if cleaning is complete
function CleaningProcessor:performCleaning(entityId, cleaningTask, dt)
  -- Calculate cleaning rate
  local cleaningRate = self:getCleaningRate(entityId, cleaningTask)
  
  -- Find dirt entities in cleaning radius
  local dirtEntities = self:findDirtInRadius(cleaningTask.targetPosition, cleaningTask.radius)
  
  if #dirtEntities == 0 then
    -- No dirt found, task is complete
    cleaningTask:markComplete()
    return true
  end

  -- Clean dirt entities
  local cleaningThisFrame = cleaningRate * dt
  local totalCleaned = 0
  
  for _, dirtEntity in ipairs(dirtEntities) do
    if totalCleaned >= cleaningThisFrame then
      break -- Reached cleaning limit for this frame
    end
    
    local dirt = EntityManager:getComponent(dirtEntity, ComponentType.DIRT)
    if dirt then
      local cleanAmount = math.min(cleaningThisFrame - totalCleaned, dirt.amount)
      dirt.amount = dirt.amount - cleanAmount
      totalCleaned = totalCleaned + cleanAmount
      
      -- Remove dirt entity if completely cleaned
      if dirt.amount <= 0 then
        self:removeDirtEntity(dirtEntity)
      end
    end
  end

  -- Update progress tracking
  cleaningTask.totalCleaned = (cleaningTask.totalCleaned or 0) + totalCleaned
  
  -- Check if all dirt in area is cleaned
  local remainingDirt = self:findDirtInRadius(cleaningTask.targetPosition, cleaningTask.radius)
  if #remainingDirt == 0 then
    cleaningTask:markComplete()
    return true
  end

  return false
end

--- Gets the cleaning rate for an entity
---@param entityId number Entity ID
---@param cleaningTask CleaningTask Cleaning task component
---@return number Cleaning rate per second
function CleaningProcessor:getCleaningRate(entityId, cleaningTask)
  -- Base cleaning rate
  local baseRate = cleaningTask.cleaningRate or self.defaultCleaningRate

  -- Check for cleaning tool bonus
  local tool = EntityManager:getComponent(entityId, ComponentType.TOOL)
  if tool and tool.cleaningBonus then
    baseRate = baseRate * tool.cleaningBonus
  end

  -- Check for entity skill bonuses
  local skills = EntityManager:getComponent(entityId, ComponentType.SKILLS)
  if skills and skills.cleaning then
    baseRate = baseRate * (1.0 + skills.cleaning * 0.1)  -- 10% per skill level
  end

  return baseRate
end

--- Finds dirt entities within a radius of a position
---@param centerPos Vec2 Center position to search around
---@param radius number Search radius
---@return number[] Array of dirt entity IDs
function CleaningProcessor:findDirtInRadius(centerPos, radius)
  local dirtEntities = {}
  
  -- Query all entities with DIRT components
  for entity, _ in pairs(EntityManager.entities) do
    local dirt = EntityManager:getComponent(entity, ComponentType.DIRT)
    local position = EntityManager:getComponent(entity, ComponentType.POSITION)
    
    if dirt and position then
      local distance = self:calculateDistance(centerPos, position)
      if distance <= radius then
        table.insert(dirtEntities, entity)
      end
    end
  end
  
  return dirtEntities
end

--- Calculates distance between two positions
---@param pos1 Vec2 First position
---@param pos2 Vec2 Second position
---@return number Distance between positions
function CleaningProcessor:calculateDistance(pos1, pos2)
  local dx = pos1.x - pos2.x
  local dy = pos1.y - pos2.y
  return math.sqrt(dx * dx + dy * dy)
end

--- Removes a dirt entity from the game world
---@param dirtEntity number Dirt entity ID
function CleaningProcessor:removeDirtEntity(dirtEntity)
  -- Remove the entity from the game world
  if EntityManager.removeEntity then
    EntityManager:removeEntity(dirtEntity)
  else
    -- Fallback: remove dirt component
    EntityManager:removeComponent(dirtEntity, ComponentType.DIRT)
  end

  Logger:debug("CleaningProcessor: Removed dirt entity " .. dirtEntity)
end

--- Checks if entity has required tools for cleaning
---@param entityId number Entity ID
---@param cleaningTask CleaningTask Cleaning task component
---@return boolean True if requirements are met
function CleaningProcessor:checkRequirements(entityId, cleaningTask)
  -- Check for required tool if specified
  if cleaningTask.requiredTool then
    local tool = EntityManager:getComponent(entityId, ComponentType.TOOL)
    if not tool or tool.type ~= cleaningTask.requiredTool then
      return false
    end

    -- Check tool durability
    if tool.durability and tool.durability <= 0 then
      return false
    end
  end

  -- Check for required skill level
  if cleaningTask.requiredSkillLevel then
    local skills = EntityManager:getComponent(entityId, ComponentType.SKILLS)
    if not skills or not skills.cleaning or skills.cleaning < cleaningTask.requiredSkillLevel then
      return false
    end
  end

  return true
end

--- Checks if cleaning area is valid
---@param targetPos Vec2 Target position
---@param radius number Cleaning radius
---@return boolean True if area is valid for cleaning
function CleaningProcessor:isValidArea(targetPos, radius)
  if not targetPos or not radius or radius <= 0 then
    return false
  end

  -- Check if position is within map bounds
  if not MapManager or not MapManager.width or not MapManager.height then
    return true -- Can't validate without map bounds
  end

  local intX = math.floor(targetPos.x + 0.5)
  local intY = math.floor(targetPos.y + 0.5)

  return intX >= 1 and intX <= MapManager.width and intY >= 1 and intY <= MapManager.height
end

--- Handles cleaning task completion
---@param entityId number Entity ID
---@param cleaningTask CleaningTask Completed cleaning task
function CleaningProcessor:handleCompletion(entityId, cleaningTask)
  -- Remove the CleaningTask component
  EntityManager:removeComponent(entityId, ComponentType.CLEANING_TASK)

  -- Return task component to pool if it's poolable
  if cleaningTask._poolable then
    local TaskComponentPool = require("game.systems.TaskComponentPool")
    TaskComponentPool:release(cleaningTask, ComponentType.CLEANING_TASK)
  end

  Logger:debug("CleaningProcessor: Completed cleaning task for entity " .. entityId)
end

--- Gets performance statistics for the last update
---@return table Performance stats
function CleaningProcessor:getStats()
  return {
    processedEntities = self.processedEntities,
    completedTasks = self.completedTasks,
    areasCleanedCount = self.areasCleanedCount
  }
end

--- Process method for TaskExecutionSystem integration
---@param entityId number Entity ID to process
---@param cleaningTask CleaningTask Cleaning task component
---@param dt number Delta time
---@return boolean Success status
function CleaningProcessor:process(entityId, cleaningTask, dt)
  if not cleaningTask or cleaningTask.isComplete then
    return true
  end

  local wasCompleted = self:processCleaning(entityId, cleaningTask, dt)
  return true
end

--- Registers this processor with TaskExecutionSystem
---@param taskExecutionSystem TaskExecutionSystem The system to register with
---@return boolean Success status
function CleaningProcessor:registerWithTaskExecutionSystem(taskExecutionSystem)
  if not taskExecutionSystem then
    Logger:error("CleaningProcessor: Invalid TaskExecutionSystem provided")
    return false
  end

  local success = taskExecutionSystem:registerProcessor(ComponentType.CLEANING_TASK, self)
  if success then
    Logger:info("CleaningProcessor: Successfully registered with TaskExecutionSystem")
  else
    Logger:error("CleaningProcessor: Failed to register with TaskExecutionSystem")
  end

  return success
end

return CleaningProcessor