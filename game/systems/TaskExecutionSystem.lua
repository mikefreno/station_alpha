local Logger = require("logger")
local enums = require("game.utils.enums")

-- Core TaskExecutionSystem that coordinates all task processing
-- This system runs each frame and orchestrates the execution of all task components
-- @type TaskExecutionSystem
local TaskExecutionSystem = {
  processors = {}, -- Registered task processors by component type
  dependencyResolver = nil, -- TaskDependencyResolver instance
  processingOrder = {}, -- Order of task type processing for optimal performance
  statistics = {
    frametime = 0,
    tasksProcessed = 0,
    taskCounts = {}, -- Count by task type
    processingTimes = {}, -- Time spent per task type
  },
  isInitialized = false,
}

-- Initialize the TaskExecutionSystem
-- Sets up processors, dependency resolver, and processing order
function TaskExecutionSystem:init()
  if self.isInitialized then
    Logger:warn("TaskExecutionSystem already initialized")
    return
  end

  -- Initialize statistics tracking
  self.statistics.taskCounts = {}
  self.statistics.processingTimes = {}

  -- Set up processing order (movement first, then actions)
  self.processingOrder = {
    enums.ComponentType.MOVEMENT_TASK,
    enums.ComponentType.MINING_TASK,
    enums.ComponentType.CONSTRUCTION_TASK,
    enums.ComponentType.CLEANING_TASK,
  }

  -- Initialize processor storage
  self.processors = {}
  for _, componentType in ipairs(self.processingOrder) do
    self.processors[componentType] = nil
    self.statistics.taskCounts[componentType] = 0
    self.statistics.processingTimes[componentType] = 0
  end

  self.isInitialized = true
  Logger:info("TaskExecutionSystem initialized successfully")
end

-- Register a task processor for a specific component type
-- @param componentType number The component type enum value
-- @param processor table The processor instance with process() method
function TaskExecutionSystem:registerProcessor(componentType, processor)
  if not self.isInitialized then
    Logger:error("TaskExecutionSystem not initialized")
    return false
  end

  if not componentType or not processor then
    Logger:error("Invalid parameters for registerProcessor")
    return false
  end

  if not processor.process then
    Logger:error("Processor must have a process() method")
    return false
  end

  self.processors[componentType] = processor
  Logger:info("Registered processor for component type: " .. tostring(componentType))
  return true
end

-- Set the dependency resolver instance
-- @param resolver table TaskDependencyResolver instance
function TaskExecutionSystem:setDependencyResolver(resolver)
  if not resolver then
    Logger:error("Invalid dependency resolver")
    return false
  end

  self.dependencyResolver = resolver
  Logger:info("Dependency resolver set successfully")
  return true
end

-- Assign a task to an entity
-- This integrates with TaskManager and component pools for efficient task creation
-- @param entityId number The entity to assign the task to
-- @param taskComponent table The task component instance
-- @param priority number Optional priority (default: 1)
function TaskExecutionSystem:assignTask(entityId, taskComponent, priority)
  if not self.isInitialized then
    Logger:error("TaskExecutionSystem not initialized")
    return false
  end

  if not entityId or not taskComponent then
    Logger:error("Invalid parameters for assignTask")
    return false
  end

  priority = priority or 1

  -- Set task priority if supported
  if taskComponent.setPriority then
    taskComponent:setPriority(priority)
  end

  -- Add component to entity through EntityManager
  local EntityManager = require("game.systems.EntityManager")
  local componentType = taskComponent:getComponentType()
  local success = EntityManager:addComponent(entityId, componentType, taskComponent)
  
  if not success then
    Logger:error("Failed to add task component to entity " .. tostring(entityId))
    return false
  end

  Logger:debug("Assigned task to entity " .. tostring(entityId) .. " with priority " .. tostring(priority))
  return true
end

-- Main update loop that processes all tasks
-- This is called every frame and orchestrates the 3-phase processing
-- @param dt number Delta time since last frame
function TaskExecutionSystem:update(dt)
  if not self.isInitialized then
    return
  end

  local frameStartTime = love.timer.getTime()
  local totalTasksProcessed = 0

  -- Phase 1: Dependency Resolution
  if self.dependencyResolver then
    local depStartTime = love.timer.getTime()
    self.dependencyResolver:resolveDependencies()
    local depTime = love.timer.getTime() - depStartTime
    Logger:debug("Dependency resolution took " .. string.format("%.3f", depTime * 1000) .. "ms")
  end

  -- Phase 2: Batch Processing (movement first, then actions)
  for _, componentType in ipairs(self.processingOrder) do
    local processor = self.processors[componentType]
    if processor then
      local procStartTime = love.timer.getTime()
      local tasksProcessed = self:processTaskType(componentType, processor, dt)
      local procTime = love.timer.getTime() - procStartTime

      -- Update statistics
      self.statistics.taskCounts[componentType] = tasksProcessed
      self.statistics.processingTimes[componentType] = procTime
      totalTasksProcessed = totalTasksProcessed + tasksProcessed

      Logger:debug(
        "Processed "
          .. tasksProcessed
          .. " "
          .. tostring(componentType)
          .. " tasks in "
          .. string.format("%.3f", procTime * 1000)
          .. "ms"
      )
    end
  end

  -- Phase 3: Completion Cleanup
  self:removeCompletedTasks()

  -- Update frame statistics
  self.statistics.frametime = love.timer.getTime() - frameStartTime
  self.statistics.tasksProcessed = totalTasksProcessed

  Logger:debug(
    "Task execution frame completed in "
      .. string.format("%.3f", self.statistics.frametime * 1000)
      .. "ms, processed "
      .. totalTasksProcessed
      .. " tasks"
  )
end

-- Process tasks of a specific type using the registered processor
-- @param componentType number The component type to process
-- @param processor table The processor to use
-- @param dt number Delta time
-- @return number Number of tasks processed
function TaskExecutionSystem:processTaskType(componentType, processor, dt)
  local EntityManager = require("game.systems.EntityManager")
  local entities = EntityManager:query(componentType)

  if not entities or #entities == 0 then
    return 0
  end

  -- Process all entities with this component type
  local processed = 0
  for _, entityId in ipairs(entities) do
    local component = EntityManager:getComponent(entityId, componentType)
    if component then
      local success, result = pcall(processor.process, processor, entityId, component, dt)
      if success then
        processed = processed + 1
      else
        Logger:error("Error processing task for entity " .. tostring(entityId) .. ": " .. tostring(result))
      end
    end
  end

  return processed
end

-- Remove completed tasks from entities
-- This cleans up finished task components and releases them back to pools
function TaskExecutionSystem:removeCompletedTasks()
  local EntityManager = require("game.systems.EntityManager")
  local TaskComponentPool = require("game.systems.TaskComponentPool")

  for _, componentType in ipairs(self.processingOrder) do
    local entities = EntityManager:query(componentType)
    if entities then
      for _, entityId in ipairs(entities) do
        local component = EntityManager:getComponent(entityId, componentType)
        if component and component.isComplete then
          -- Remove component from entity
          EntityManager:removeComponent(entityId, componentType)

          -- Release component back to pool
          TaskComponentPool:release(componentType, component)

          Logger:debug("Removed completed task from entity " .. tostring(entityId))
        end
      end
    end
  end
end

-- Get current performance statistics
-- @return table Statistics about task processing performance
function TaskExecutionSystem:getStatistics()
  return {
    frametime = self.statistics.frametime,
    tasksProcessed = self.statistics.tasksProcessed,
    taskCounts = self.statistics.taskCounts,
    processingTimes = self.statistics.processingTimes,
    averageTaskTime = self.statistics.tasksProcessed > 0
        and (self.statistics.frametime / self.statistics.tasksProcessed)
      or 0,
  }
end

-- Reset performance statistics
function TaskExecutionSystem:resetStatistics()
  self.statistics.frametime = 0
  self.statistics.tasksProcessed = 0
  for componentType, _ in pairs(self.statistics.taskCounts) do
    self.statistics.taskCounts[componentType] = 0
    self.statistics.processingTimes[componentType] = 0
  end
end

-- Get the number of registered processors
-- @return number Number of registered processors
function TaskExecutionSystem:getProcessorCount()
  local count = 0
  for _, processor in pairs(self.processors) do
    if processor then
      count = count + 1
    end
  end
  return count
end

-- Check if the system has a processor for a given component type
-- @param componentType number The component type to check
-- @return boolean True if processor is registered
function TaskExecutionSystem:hasProcessor(componentType)
  return self.processors[componentType] ~= nil
end

return TaskExecutionSystem
