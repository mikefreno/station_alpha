local Logger = require("logger")
local enums = require("utils.enums")

-- TaskDependencyResolver system that automatically manages task dependencies
-- This system analyzes action tasks and inserts movement tasks when entities
-- are not positioned correctly to execute their assigned tasks
-- @type TaskDependencyResolver
local TaskDependencyResolver = {

  -- Action component types that require position validation
  actionTaskTypes = {
    enums.ComponentType.MINING_TASK,
    enums.ComponentType.CONSTRUCTION_TASK,
    enums.ComponentType.CLEANING_TASK,
  },
  -- Performance tracking
  statistics = {
    dependenciesResolved = 0,
    movementTasksInjected = 0,
    entitiesAnalyzed = 0,
    resolveTime = 0,
  },
  isInitialized = false,
}

-- Initialize the TaskDependencyResolver
function TaskDependencyResolver:init()
  if self.isInitialized then
    Logger:warn("TaskDependencyResolver already initialized")
    return
  end

  -- Reset statistics
  self.statistics.dependenciesResolved = 0
  self.statistics.movementTasksInjected = 0
  self.statistics.entitiesAnalyzed = 0
  self.statistics.resolveTime = 0

  self.isInitialized = true
  Logger:info("TaskDependencyResolver initialized successfully")
end

-- Main dependency resolution method called by TaskExecutionSystem
-- Analyzes all entities with action tasks and inserts movement dependencies as needed
function TaskDependencyResolver:resolveDependencies()
  if not self.isInitialized then
    Logger:error("TaskDependencyResolver not initialized")
    return
  end

  local startTime = love.timer.getTime()
  local dependenciesResolved = 0
  local movementTasksInjected = 0
  local entitiesAnalyzed = 0

  local EntityManager = require("systems.EntityManager")

  -- Process each action task type
  for _, taskType in ipairs(self.actionTaskTypes) do
    local entities = EntityManager:query(taskType)
    if entities then
      for _, entityId in ipairs(entities) do
        entitiesAnalyzed = entitiesAnalyzed + 1

        local resolved, movementAdded = self:resolveEntityDependencies(entityId, taskType)
        if resolved then
          dependenciesResolved = dependenciesResolved + 1
        end
        if movementAdded then
          movementTasksInjected = movementTasksInjected + 1
        end
      end
    end
  end

  -- Update statistics
  self.statistics.dependenciesResolved = dependenciesResolved
  self.statistics.movementTasksInjected = movementTasksInjected
  self.statistics.entitiesAnalyzed = entitiesAnalyzed
  self.statistics.resolveTime = love.timer.getTime() - startTime

  if dependenciesResolved > 0 then
    Logger:debug(
      "Resolved "
        .. dependenciesResolved
        .. " dependencies, injected "
        .. movementTasksInjected
        .. " movement tasks in "
        .. string.format("%.3f", self.statistics.resolveTime * 1000)
        .. "ms"
    )
  end
end

-- Resolve dependencies for a specific entity with an action task
-- @param entityId number The entity ID to analyze
-- @param taskType number The action task component type
-- @return boolean, boolean (dependencies_resolved, movement_task_added)
function TaskDependencyResolver:resolveEntityDependencies(entityId, taskType)
  local EntityManager = require("systems.EntityManager")

  -- Get the action task component
  local actionTask = EntityManager:getComponent(entityId, taskType)
  if not actionTask then
    return false, false
  end

  -- Get entity position
  local position = EntityManager:getComponent(entityId, enums.ComponentType.POSITION)
  if not position then
    Logger:warn("Entity " .. tostring(entityId) .. " has action task but no position component")
    return false, false
  end

  -- Check if entity is already correctly positioned for the task
  if actionTask:isInRange(position) then
    return true, false -- Dependencies resolved, no movement needed
  end

  -- Check if entity already has a movement task
  local existingMovement = EntityManager:getComponent(entityId, enums.ComponentType.MOVEMENT_TASK)
  if existingMovement then
    -- Verify existing movement task is going to the correct target
    local actionTargetPos = actionTask:getTargetPosition()
    if actionTargetPos and self:isMovementTaskValid(existingMovement, actionTargetPos, actionTask.requiredDistance) then
      return true, false -- Dependencies resolved by existing movement
    else
      -- Remove invalid movement task and create a new one
      EntityManager:removeComponent(entityId, enums.ComponentType.MOVEMENT_TASK)
      Logger:debug("Removed invalid movement task from entity " .. tostring(entityId))
    end
  end

  -- Create and assign new movement task
  local movementTask = self:createMovementTask(actionTask)
  if movementTask then
    EntityManager:addComponent(entityId, enums.ComponentType.MOVEMENT_TASK, movementTask)
    Logger:debug("Injected movement task for entity " .. tostring(entityId) .. " -> " .. tostring(taskType))
    return true, true
  end

  Logger:error("Failed to create movement task for entity " .. tostring(entityId))
  return false, false
end

-- Create a movement task to position entity for action task execution
-- @param actionTask table The action task that requires positioning
-- @return MovementTask? The created movement task or nil if failed
function TaskDependencyResolver:createMovementTask(actionTask)
  local targetPosition = actionTask:getTargetPosition()
  if not targetPosition then
    Logger:error("Action task has no valid target position")
    return nil
  end

  -- Create movement task with required distance buffer
  local MovementTask = require("components.MovementTask")
  local movementTask = MovementTask.newFromPool(
    targetPosition,
    actionTask.requiredDistance,
    1.0 -- Default movement speed
  )

  if not movementTask then
    Logger:error("Failed to create MovementTask from pool")
    return nil
  end

  -- Set up movement task for pathfinding integration
  -- The actual path will be computed by the movement processor
  movementTask:setPath({ targetPosition })

  Logger:debug("Created movement task to position " .. targetPosition.x .. "," .. targetPosition.y)
  return movementTask
end

-- Validates if existing movement task is appropriate for the action task
-- @param movementTask table The existing movement task
-- @param targetPosition Vec2 The action task's target position
-- @param requiredDistance number The action task's required distance
-- @return boolean True if movement task is valid for the action
function TaskDependencyResolver:isMovementTaskValid(movementTask, targetPosition, requiredDistance)
  if not movementTask or not targetPosition then
    return false
  end

  -- Check if movement target matches action target
  local movementTarget = movementTask.targetPosition
  if not movementTarget then
    return false
  end

  local dx = movementTarget.x - targetPosition.x
  local dy = movementTarget.y - targetPosition.y
  local distance = math.sqrt(dx * dx + dy * dy)

  -- Movement task is valid if it gets within required distance of action target
  return distance <= requiredDistance
end

-- Check if an entity requires movement for any of its action tasks
-- @param entityId number The entity to check
-- @return boolean True if entity needs movement for task execution
function TaskDependencyResolver:entityRequiresMovement(entityId)
  local EntityManager = require("systems.EntityManager")

  -- Get entity position
  local position = EntityManager:getComponent(entityId, enums.ComponentType.POSITION)
  if not position then
    return false
  end

  -- Check each action task type
  for _, taskType in ipairs(self.actionTaskTypes) do
    local actionTask = EntityManager:getComponent(entityId, taskType)
    if actionTask and not actionTask:isInRange(position) then
      return true
    end
  end

  return false
end

-- Get all entities that require movement dependencies
-- @return table Array of entity IDs that need movement tasks
function TaskDependencyResolver:getEntitiesRequiringMovement()
  local entitiesNeedingMovement = {}
  local EntityManager = require("systems.EntityManager")

  for _, taskType in ipairs(self.actionTaskTypes) do
    local entities = EntityManager:query(taskType)
    if entities then
      for _, entityId in ipairs(entities) do
        if self:entityRequiresMovement(entityId) then
          table.insert(entitiesNeedingMovement, entityId)
        end
      end
    end
  end

  return entitiesNeedingMovement
end
-- Analyze dependency chains for complex task sequences
-- This method identifies potential conflicts and optimizes task ordering
-- @param entityId number The entity to analyze
-- @return table Analysis results with dependency information
function TaskDependencyResolver:analyzeDependencyChains(entityId)
  local EntityManager = require("systems.EntityManager")
  local analysis = {
    hasMovementTask = false,
    actionTasks = {},
    conflictingTargets = false,
    estimatedMovementTime = 0,
    totalEstimatedTime = 0,
  }

  -- Check for existing movement task
  local movementTask = EntityManager:getComponent(entityId, enums.ComponentType.MOVEMENT_TASK)
  analysis.hasMovementTask = (movementTask ~= nil)

  -- Collect all action tasks
  for _, taskType in ipairs(self.actionTaskTypes) do
    local actionTask = EntityManager:getComponent(entityId, taskType)
    if actionTask then
      table.insert(analysis.actionTasks, {
        type = taskType,
        task = actionTask,
        targetPosition = actionTask:getTargetPosition(),
        estimatedDuration = actionTask.estimatedDuration,
      })
    end
  end

  -- Analyze for conflicting targets (multiple tasks requiring different positions)
  if #analysis.actionTasks > 1 then
    local firstTarget = analysis.actionTasks[1].targetPosition
    for i = 2, #analysis.actionTasks do
      local currentTarget = analysis.actionTasks[i].targetPosition
      if firstTarget and currentTarget then
        local dx = firstTarget.x - currentTarget.x
        local dy = firstTarget.y - currentTarget.y
        local distance = math.sqrt(dx * dx + dy * dy)
        -- If tasks require significantly different positions, mark as conflicting
        if distance > 2.0 then
          analysis.conflictingTargets = true
          break
        end
      end
    end
  end

  -- Calculate estimated times
  if movementTask then
    analysis.estimatedMovementTime = movementTask.estimatedDuration
  end

  for _, taskInfo in ipairs(analysis.actionTasks) do
    analysis.totalEstimatedTime = analysis.totalEstimatedTime + taskInfo.estimatedDuration
  end
  analysis.totalEstimatedTime = analysis.totalEstimatedTime + analysis.estimatedMovementTime

  return analysis
end

-- Get current performance statistics
-- @return table Statistics about dependency resolution performance
function TaskDependencyResolver:getStatistics()
  return {
    dependenciesResolved = self.statistics.dependenciesResolved,
    movementTasksInjected = self.statistics.movementTasksInjected,
    entitiesAnalyzed = self.statistics.entitiesAnalyzed,
    resolveTime = self.statistics.resolveTime,
    averageResolveTimePerEntity = self.statistics.entitiesAnalyzed > 0
        and (self.statistics.resolveTime / self.statistics.entitiesAnalyzed)
      or 0,
  }
end

-- Reset performance statistics
function TaskDependencyResolver:resetStatistics()
  self.statistics.dependenciesResolved = 0
  self.statistics.movementTasksInjected = 0
  self.statistics.entitiesAnalyzed = 0
  self.statistics.resolveTime = 0
end

-- Get the list of action task types that require dependency resolution
-- @return table Array of ComponentType enum values
function TaskDependencyResolver:getActionTaskTypes()
  return self.actionTaskTypes
end

-- Check if the resolver is properly initialized
-- @return boolean True if initialized and ready to use
function TaskDependencyResolver:isReady()
  return self.isInitialized
end

return TaskDependencyResolver
