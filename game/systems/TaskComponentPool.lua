local enums = require("game.utils.enums")
local Logger = require("logger")
local ComponentType = enums.ComponentType

--- @class TaskComponentPool
--- High-performance object pooling system for task components
--- Reduces memory allocation overhead and garbage collection pressure
local TaskComponentPool = {}

-- Pool storage and management
TaskComponentPool.pools = {
  [ComponentType.MOVEMENT_TASK] = {},
  [ComponentType.MINING_TASK] = {},
  [ComponentType.CONSTRUCTION_TASK] = {},
  [ComponentType.CLEANING_TASK] = {},
}

-- Pool size tracking
TaskComponentPool.poolSizes = {
  [ComponentType.MOVEMENT_TASK] = 0,
  [ComponentType.MINING_TASK] = 0,
  [ComponentType.CONSTRUCTION_TASK] = 0,
  [ComponentType.CLEANING_TASK] = 0,
}

-- Performance statistics
TaskComponentPool.poolStats = {
  [ComponentType.MOVEMENT_TASK] = { acquired = 0, released = 0, created = 0, reused = 0 },
  [ComponentType.MINING_TASK] = { acquired = 0, released = 0, created = 0, reused = 0 },
  [ComponentType.CONSTRUCTION_TASK] = { acquired = 0, released = 0, created = 0, reused = 0 },
  [ComponentType.CLEANING_TASK] = { acquired = 0, released = 0, created = 0, reused = 0 },
}

-- Pool configuration
TaskComponentPool.config = {
  initialPoolSize = 10,
  maxPoolSize = 100,
  shrinkThreshold = 50, -- Shrink when this many unused components
  cleanupInterval = 60.0, -- Cleanup every 60 seconds
  lastCleanupTime = 0,
}

-- Component class mappings for creation
TaskComponentPool.componentClasses = {}

--- Initialize the pool system
--- @param gameTime number Current game time for cleanup scheduling
function TaskComponentPool:init(gameTime)
  self.config.lastCleanupTime = gameTime or 0

  -- Register component classes
  self.componentClasses[ComponentType.MOVEMENT_TASK] = require("game.components.MovementTask")
  self.componentClasses[ComponentType.MINING_TASK] = require("game.components.MiningTask")
  self.componentClasses[ComponentType.CONSTRUCTION_TASK] = require("game.components.ConstructionTask")
  self.componentClasses[ComponentType.CLEANING_TASK] = require("game.components.CleaningTask")

  -- Pre-allocate initial pool sizes
  for componentType, _ in pairs(self.pools) do
    self:preAllocate(componentType, self.config.initialPoolSize)
  end

  Logger:info("TaskComponentPool initialized with " .. self.config.initialPoolSize .. " components per type")
end

--- Get a component from the pool or create a new one
--- @param componentType number The ComponentType enum value
--- @return table|nil The component instance or nil if invalid type
function TaskComponentPool:acquire(componentType)
  local pool = self.pools[componentType]
  if not pool then
    Logger:error("TaskComponentPool:acquire - Invalid component type: " .. tostring(componentType))
    return nil
  end

  local stats = self.poolStats[componentType]
  stats.acquired = stats.acquired + 1

  -- Try to reuse from pool
  if #pool > 0 then
    local component = table.remove(pool)
    self.poolSizes[componentType] = self.poolSizes[componentType] - 1
    stats.reused = stats.reused + 1
    return component
  end

  -- Create new component if pool is empty
  local componentClass = self.componentClasses[componentType]
  if not componentClass then
    Logger:error("TaskComponentPool:acquire - No class registered for component type: " .. tostring(componentType))
    return nil
  end

  local component = componentClass.new()
  component._poolable = true
  stats.created = stats.created + 1

  return component
end

--- Return a component to the pool after resetting its state
--- @param component table The component to return to pool
--- @param componentType number The ComponentType enum value
function TaskComponentPool:release(component, componentType)
  if not component then
    Logger:warn("TaskComponentPool:release - Attempted to release nil component")
    return
  end

  local pool = self.pools[componentType]
  if not pool then
    Logger:error("TaskComponentPool:release - Invalid component type: " .. tostring(componentType))
    return
  end

  -- Check if component is poolable
  if not component._poolable or not component.reset then
    Logger:warn("TaskComponentPool:release - Component is not poolable or missing reset method")
    return
  end

  -- Don't exceed maximum pool size
  if self.poolSizes[componentType] >= self.config.maxPoolSize then
    Logger:debug("TaskComponentPool:release - Pool at max size, discarding component")
    return
  end

  -- Reset component state and return to pool
  component:reset()
  table.insert(pool, component)
  self.poolSizes[componentType] = self.poolSizes[componentType] + 1

  local stats = self.poolStats[componentType]
  stats.released = stats.released + 1
end

--- Pre-allocate components to warm up the pool
--- @param componentType number The ComponentType enum value
--- @param count number Number of components to pre-allocate
function TaskComponentPool:preAllocate(componentType, count)
  local pool = self.pools[componentType]
  if not pool then
    Logger:error("TaskComponentPool:preAllocate - Invalid component type: " .. tostring(componentType))
    return
  end

  local componentClass = self.componentClasses[componentType]
  if not componentClass then
    Logger:error("TaskComponentPool:preAllocate - No class registered for component type: " .. tostring(componentType))
    return
  end

  for _ = 1, count do
    if self.poolSizes[componentType] >= self.config.maxPoolSize then
      break
    end

    -- Try to create component with empty parameters for pooling
  local component = componentClass.new()
    if not component then
      -- Component requires parameters, skip pre-allocation
      Logger:debug("TaskComponentPool:preAllocate - Skipping pre-allocation for type " .. tostring(componentType) .. " (requires parameters)")
      break
    end
    
    component._poolable = true
    component:reset()

    table.insert(pool, component)
    self.poolSizes[componentType] = self.poolSizes[componentType] + 1
  end

  Logger:debug(
    "TaskComponentPool:preAllocate - Pre-allocated " .. count .. " components for type " .. tostring(componentType)
  )
end

--- Get pool performance statistics
--- @return table totalStats Statistics for all component types
--- @return table poolStats Individual component type statistics
function TaskComponentPool:getPoolStats()
  local totalStats = {
    totalAcquired = 0,
    totalReleased = 0,
    totalCreated = 0,
    totalReused = 0,
    poolSizes = {},
    reuseRates = {},
  }

  for componentType, stats in pairs(self.poolStats) do
    totalStats.totalAcquired = totalStats.totalAcquired + stats.acquired
    totalStats.totalReleased = totalStats.totalReleased + stats.released
    totalStats.totalCreated = totalStats.totalCreated + stats.created
    totalStats.totalReused = totalStats.totalReused + stats.reused

    totalStats.poolSizes[componentType] = self.poolSizes[componentType]

    -- Calculate reuse rate
    if stats.acquired > 0 then
      totalStats.reuseRates[componentType] = stats.reused / stats.acquired
    else
      totalStats.reuseRates[componentType] = 0
    end
  end

  return totalStats, self.poolStats
end

--- Clean up oversized pools
--- @param gameTime number Current game time
function TaskComponentPool:cleanup(gameTime)
  if gameTime - self.config.lastCleanupTime < self.config.cleanupInterval then
    return
  end

  local totalCleaned = 0

  for componentType, pool in pairs(self.pools) do
    local currentSize = self.poolSizes[componentType]

    -- Shrink pool if it has too many unused components
    if currentSize > self.config.shrinkThreshold then
      local targetSize = math.max(self.config.initialPoolSize, math.floor(currentSize / 2))
      local toRemove = currentSize - targetSize

      for _ = 1, toRemove do
        table.remove(pool)
        self.poolSizes[componentType] = self.poolSizes[componentType] - 1
        totalCleaned = totalCleaned + 1
      end

      Logger:debug(
        "TaskComponentPool:cleanup - Cleaned " .. toRemove .. " components from type " .. tostring(componentType)
      )
    end
  end

  if totalCleaned > 0 then
    Logger:info("TaskComponentPool:cleanup - Cleaned " .. totalCleaned .. " total components")
  end

  self.config.lastCleanupTime = gameTime
end

--- Get the current pool size for a component type
--- @param componentType number The ComponentType enum value
--- @return number The current pool size
function TaskComponentPool:getPoolSize(componentType)
  return self.poolSizes[componentType] or 0
end

--- Check if a component type is supported
--- @param componentType number The ComponentType enum value
--- @return boolean Whether the component type is supported
function TaskComponentPool:isSupported(componentType)
  return self.pools[componentType] ~= nil
end

return TaskComponentPool
