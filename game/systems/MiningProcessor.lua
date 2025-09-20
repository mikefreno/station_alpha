local ComponentType = require("game.utils.enums").ComponentType
local Logger = require("logger")
local PerformanceMonitor = require("game.systems.PerformanceMonitor")

---@class MiningProcessor
---@field defaultSwingDuration number Seconds per mining swing
---@field defaultSwingsPerResource number Swings needed per resource unit
---@field processedEntities number Statistics: entities processed this frame
---@field completedTasks number Statistics: tasks completed this frame
---@field resourcesGenerated number Statistics: resources generated this frame
---@field performanceMonitor PerformanceMonitor Performance tracking system
local MiningProcessor = {}
MiningProcessor.__index = MiningProcessor

--- Creates a new MiningProcessor instance
---@return MiningProcessor
function MiningProcessor.new()
  local self = setmetatable({}, MiningProcessor)

  self.defaultSwingDuration = 1.0
  self.defaultSwingsPerResource = 5
  self.processedEntities = 0
  self.completedTasks = 0
  self.resourcesGenerated = 0
  
  -- Initialize performance monitoring
  self.performanceMonitor = PerformanceMonitor
  if not self.performanceMonitor.isInitialized then
    self.performanceMonitor:init()
  end

  return self
end

--- Batch processes all entities with MiningTask components
---@param entities number[] Array of entity IDs with mining tasks
---@param dt number Delta time for this frame
function MiningProcessor:processBatch(entities, dt)
  if not entities or #entities == 0 then
    return
  end

  -- Start performance monitoring
  local batchStartTime = love.timer.getTime()

  self.processedEntities = 0
  self.completedTasks = 0
  self.resourcesGenerated = 0

  for _, entityId in ipairs(entities) do
    local miningTask = EntityManager:getComponent(entityId, ComponentType.MINING_TASK)
    if miningTask and not miningTask.isComplete then
      local wasCompleted = self:processMining(entityId, miningTask, dt)
      self.processedEntities = self.processedEntities + 1

      if wasCompleted then
        self.completedTasks = self.completedTasks + 1
      end
    end
  end
  
  -- Record performance metrics
  local batchTime = love.timer.getTime() - batchStartTime
  self.performanceMonitor:recordSystemMetrics("MiningProcessor", batchTime, #entities)
  self.performanceMonitor:recordTaskMetrics(ComponentType.MINING_TASK, batchTime, self.processedEntities, #entities)
end

--- Processes mining for a single entity
---@param entityId number Entity ID
---@param miningTask MiningTask Mining task component
---@param dt number Delta time
---@return boolean True if task was completed
function MiningProcessor:processMining(entityId, miningTask, dt)
  -- Check if entity has required tools
  if not self:checkRequirements(entityId, miningTask) then
    Logger:debug("MiningProcessor: Entity " .. entityId .. " lacks required tools for mining")
    return false
  end

  -- Check if target still exists and is valid
  if not self:isValidTarget(miningTask.target) then
    Logger:debug("MiningProcessor: Invalid mining target for entity " .. entityId)
    miningTask:markComplete()
    return true
  end

  -- Update mining swing progress
  local completed = self:processMiningSwing(entityId, miningTask, dt)
  if completed then
    self:handleCompletion(entityId, miningTask)
    return true
  end

  return false
end

--- Processes a mining swing for the entity
---@param entityId number Entity ID
---@param miningTask MiningTask Mining task component
---@param dt number Delta time
---@return boolean True if mining task is complete
function MiningProcessor:processMiningSwing(entityId, miningTask, dt)
  -- Update swing timer
  miningTask.swingTimer = (miningTask.swingTimer or 0) + dt

  -- Check if swing is complete
  local swingDuration = miningTask.swingDuration or self.defaultSwingDuration
  if miningTask.swingTimer >= swingDuration then
    -- Reset swing timer
    miningTask.swingTimer = 0

    -- Process the swing
    return self:executeSwing(entityId, miningTask)
  end

  return false
end

--- Executes a single mining swing
---@param entityId number Entity ID
---@param miningTask MiningTask Mining task component
---@return boolean True if mining task is complete
function MiningProcessor:executeSwing(entityId, miningTask)
  local targetHealth = EntityManager:getComponent(miningTask.target, ComponentType.HEALTH)
  if not targetHealth then
    Logger:error("MiningProcessor: Target has no health component")
    miningTask:markComplete()
    return true
  end

  -- Calculate mining damage
  local miningPower = self:getMiningPower(entityId, miningTask)
  local damage = miningPower

  -- Apply damage to target
  targetHealth.current = targetHealth.current - damage
  Logger:debug("MiningProcessor: Entity " .. entityId .. " dealt " .. damage .. " mining damage")

  -- Check if target is destroyed
  if targetHealth.current <= 0 then
    self:generateResources(entityId, miningTask)
    self:destroyTarget(miningTask.target)
    miningTask:markComplete()
    return true
  end

  -- Update mining progress
  self:updateProgress(miningTask, damage)
  return false
end

--- Gets the mining power for an entity
---@param entityId number Entity ID
---@param miningTask MiningTask Mining task component
---@return number Mining power/damage per swing
function MiningProcessor:getMiningPower(entityId, miningTask)
  -- Base mining power
  local basePower = 1.0

  -- Check for mining tool bonus
  local tool = EntityManager:getComponent(entityId, ComponentType.TOOL)
  if tool and tool.miningBonus then
    basePower = basePower * tool.miningBonus
  end

  -- Check for entity skill bonuses
  local skills = EntityManager:getComponent(entityId, ComponentType.SKILLS)
  if skills and skills.mining then
    basePower = basePower * (1.0 + skills.mining * 0.1)  -- 10% per skill level
  end

  -- Task-specific modifiers
  local modifier = miningTask.powerModifier or 1.0
  return basePower * modifier
end

--- Checks if entity has required tools and resources for mining
---@param entityId number Entity ID
---@param miningTask MiningTask Mining task component
---@return boolean True if requirements are met
function MiningProcessor:checkRequirements(entityId, miningTask)
  -- Check for required tool if specified
  if miningTask.requiredTool then
    local tool = EntityManager:getComponent(entityId, ComponentType.TOOL)
    if not tool or tool.type ~= miningTask.requiredTool then
      return false
    end

    -- Check tool durability
    if tool.durability and tool.durability <= 0 then
      return false
    end
  end

  -- Check for required skill level
  if miningTask.requiredSkillLevel then
    local skills = EntityManager:getComponent(entityId, ComponentType.SKILLS)
    if not skills or not skills.mining or skills.mining < miningTask.requiredSkillLevel then
      return false
    end
  end

  return true
end

--- Checks if mining target is valid
---@param targetId number Target entity ID
---@return boolean True if target is valid for mining
function MiningProcessor:isValidTarget(targetId)
  if not targetId then
    return false
  end

  -- Check if target still exists
  local health = EntityManager:getComponent(targetId, ComponentType.HEALTH)
  if not health or health.current <= 0 then
    return false
  end

  -- Check if target is mineable
  local mineable = EntityManager:getComponent(targetId, ComponentType.MINEABLE)
  return mineable ~= nil
end

--- Updates mining progress tracking
---@param miningTask MiningTask Mining task component
---@param damage number Damage dealt this swing
function MiningProcessor:updateProgress(miningTask, damage)
  miningTask.totalDamageDealt = (miningTask.totalDamageDealt or 0) + damage
  miningTask.swingsCompleted = (miningTask.swingsCompleted or 0) + 1

  -- Update progress percentage if target health is known
  local targetHealth = EntityManager:getComponent(miningTask.target, ComponentType.HEALTH)
  if targetHealth then
    local totalHealth = targetHealth.max or targetHealth.current
    local damageProgress = miningTask.totalDamageDealt / totalHealth
    miningTask.progress = math.min(damageProgress, 1.0)
  end
end

--- Generates resources when mining is complete
---@param entityId number Entity ID that performed mining
---@param miningTask MiningTask Completed mining task
function MiningProcessor:generateResources(entityId, miningTask)
  local mineable = EntityManager:getComponent(miningTask.target, ComponentType.MINEABLE)
  if not mineable then
    return
  end

  -- Calculate resource yield
  local baseYield = mineable.resourceYield or 1
  local bonusYield = self:calculateBonusYield(entityId, miningTask)
  local totalYield = math.floor(baseYield * bonusYield)

  if totalYield > 0 then
    -- Add resources to entity inventory
    self:addResourcesToInventory(entityId, mineable.resourceType, totalYield)
    self.resourcesGenerated = self.resourcesGenerated + totalYield

    Logger:debug("MiningProcessor: Generated " .. totalYield .. " " .. (mineable.resourceType or "resources"))
  end
end

--- Calculates bonus yield from tools and skills
---@param entityId number Entity ID
---@param miningTask MiningTask Mining task component
---@return number Yield multiplier
function MiningProcessor:calculateBonusYield(entityId, miningTask)
  local multiplier = 1.0

  -- Tool bonus
  local tool = EntityManager:getComponent(entityId, ComponentType.TOOL)
  if tool and tool.yieldBonus then
    multiplier = multiplier * tool.yieldBonus
  end

  -- Skill bonus
  local skills = EntityManager:getComponent(entityId, ComponentType.SKILLS)
  if skills and skills.mining then
    multiplier = multiplier * (1.0 + skills.mining * 0.05)  -- 5% per skill level
  end

  return multiplier
end

--- Adds resources to entity's inventory
---@param entityId number Entity ID
---@param resourceType string Type of resource
---@param amount number Amount to add
function MiningProcessor:addResourcesToInventory(entityId, resourceType, amount)
  local inventory = EntityManager:getComponent(entityId, ComponentType.INVENTORY)
  if not inventory then
    -- Create inventory if it doesn't exist
    inventory = { items = {} }
    EntityManager:addComponent(entityId, ComponentType.INVENTORY, inventory)
  end

  -- Add resources to inventory
  if not inventory.items[resourceType] then
    inventory.items[resourceType] = 0
  end
  inventory.items[resourceType] = inventory.items[resourceType] + amount
end

--- Destroys the mining target
---@param targetId number Target entity ID
function MiningProcessor:destroyTarget(targetId)
  -- Remove the entity from the game world
  if EntityManager.removeEntity then
    EntityManager:removeEntity(targetId)
  else
    -- Fallback: mark as destroyed
    local health = EntityManager:getComponent(targetId, ComponentType.HEALTH)
    if health then
      health.current = 0
    end
  end

  Logger:debug("MiningProcessor: Destroyed mining target " .. targetId)
end

--- Handles mining task completion
---@param entityId number Entity ID
---@param miningTask MiningTask Completed mining task
function MiningProcessor:handleCompletion(entityId, miningTask)
  -- Remove the MiningTask component
  EntityManager:removeComponent(entityId, ComponentType.MINING_TASK)

  -- Return task component to pool if it's poolable
  if miningTask._poolable then
    local TaskComponentPool = require("game.systems.TaskComponentPool")
    TaskComponentPool:release(miningTask, ComponentType.MINING_TASK)
  end

  Logger:debug("MiningProcessor: Completed mining task for entity " .. entityId)
end

--- Gets performance statistics for the last update
---@return table Performance stats
function MiningProcessor:getStats()
  return {
    processedEntities = self.processedEntities,
    completedTasks = self.completedTasks,
    resourcesGenerated = self.resourcesGenerated
  }
end

--- Process method for TaskExecutionSystem integration
---@param entityId number Entity ID to process
---@param miningTask MiningTask Mining task component
---@param dt number Delta time
---@return boolean Success status
function MiningProcessor:process(entityId, miningTask, dt)
  if not miningTask or miningTask.isComplete then
    return true
  end

  local wasCompleted = self:processMining(entityId, miningTask, dt)
  return true
end

--- Registers this processor with TaskExecutionSystem
---@param taskExecutionSystem TaskExecutionSystem The system to register with
---@return boolean Success status
function MiningProcessor:registerWithTaskExecutionSystem(taskExecutionSystem)
  if not taskExecutionSystem then
    Logger:error("MiningProcessor: Invalid TaskExecutionSystem provided")
    return false
  end

  local success = taskExecutionSystem:registerProcessor(ComponentType.MINING_TASK, self)
  if success then
    Logger:info("MiningProcessor: Successfully registered with TaskExecutionSystem")
  else
    Logger:error("MiningProcessor: Failed to register with TaskExecutionSystem")
  end

  return success
end

return MiningProcessor