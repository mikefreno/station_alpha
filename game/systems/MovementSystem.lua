local ComponentType = require("game.utils.enums").ComponentType
local Vec2 = require("game.utils.Vec2")
local constants = require("game.utils.constants")
local Logger = require("logger")
local SpatialIndex = require("game.systems.SpatialIndex")
local PerformanceMonitor = require("game.systems.PerformanceMonitor")

---@class MovementSystem
---@field spatialIndex SpatialIndex Spatial optimization for proximity queries
---@field performanceMonitor PerformanceMonitor Performance tracking system
---@field movementSpeed number Default movement speed (tiles/second)
---@field waypointThreshold number Distance to consider waypoint reached
---@field processedEntities number Statistics: entities processed this frame
---@field completedMovements number Statistics: movements completed this frame
local MovementSystem = {}
MovementSystem.__index = MovementSystem

--- Creates a new MovementSystem instance
---@return MovementSystem
function MovementSystem.new()
  local self = setmetatable({}, MovementSystem)
  
  -- Initialize performance systems
  self.spatialIndex = SpatialIndex
  self.performanceMonitor = PerformanceMonitor
  
  -- Initialize if not already done
  if not self.spatialIndex.isInitialized then
    self.spatialIndex:init()
  end
  if not self.performanceMonitor.isInitialized then
    self.performanceMonitor:init()
  end
  
  self.movementSpeed = 1.0
  self.waypointThreshold = 0.1
  self.processedEntities = 0
  self.completedMovements = 0
  
  return self
end

--- Batch processes all entities with MovementTask components
---@param movingEntities number[] Array of entity IDs with movement tasks
---@param dt number Delta time for this frame
function MovementSystem:processBatch(movingEntities, dt)
  if not movingEntities or #movingEntities == 0 then
    return
  end
  
  -- Start performance monitoring
  local systemStartTime = love.timer.getTime()
  
  self.processedEntities = 0
  self.completedMovements = 0
  
  -- Sort entities by spatial proximity for cache-friendly processing
  self:sortEntitiesByProximity(movingEntities)
  
  for _, entity in ipairs(movingEntities) do
    local movementTask = EntityManager:getComponent(entity, ComponentType.MOVEMENT_TASK)
    local position = EntityManager:getComponent(entity, ComponentType.POSITION)
    local velocity = EntityManager:getComponent(entity, ComponentType.VELOCITY)
    
    if movementTask and position then
      -- Update entity position in spatial index
      self.spatialIndex:updateEntity(entity, position.x, position.y)
      
      local wasCompleted = self:updateMovement(entity, movementTask, position, velocity, dt)
      self.processedEntities = self.processedEntities + 1
      
      if wasCompleted then
        self.completedMovements = self.completedMovements + 1
        -- Remove from spatial index when movement completes
        self.spatialIndex:removeEntity(entity)
      end
    end
  end
  
  -- Record performance metrics
  local systemTime = love.timer.getTime() - systemStartTime
  self.performanceMonitor:recordSystemMetrics("MovementSystem", systemTime, #movingEntities)
  self.performanceMonitor:recordTaskMetrics(ComponentType.MOVEMENT_TASK, systemTime, self.processedEntities, #movingEntities)
end

--- Updates movement for a single entity
---@param entity number Entity ID
---@param movementTask MovementTask Movement task component
---@param position Vec2 Position component
---@param velocity Vec2? Velocity component (optional)
---@param dt number Delta time
---@return boolean True if movement was completed
function MovementSystem:updateMovement(entity, movementTask, position, velocity, dt)
  -- Early exit if task is already complete
  if movementTask.isComplete then
    return true
  end
  
  -- Check if we have a valid path, if not try to create one
  if not movementTask:hasValidPath() then
    if not self:generatePath(entity, movementTask, position) then
      Logger:error("MovementSystem: Failed to generate path for entity " .. entity)
      movementTask:markComplete()
      return true
    end
  end
  
  -- Update movement state and check for completion
  local shouldContinue = movementTask:update(position)
  if not shouldContinue then
    -- Movement completed, clean up
    self:completeMovement(entity, movementTask, velocity)
    return true
  end
  
  -- Calculate movement for this frame
  local currentTarget = movementTask:getCurrentTarget()
  if currentTarget then
    self:moveTowardsTarget(entity, position, velocity, currentTarget, movementTask.movementSpeed, dt)
  end
  
  return false
end

--- Moves entity towards the current target position
---@param entity number Entity ID
---@param position Vec2 Position component
---@param velocity Vec2? Velocity component
---@param target Vec2 Current target position
---@param speedModifier number Movement speed modifier
---@param dt number Delta time
function MovementSystem:moveTowardsTarget(entity, position, velocity, target, speedModifier, dt)
  -- Calculate direction to target
  local directionX = target.x - position.x
  local directionY = target.y - position.y
  local distance = math.sqrt(directionX * directionX + directionY * directionY)

  if distance < 1e-6 then
    -- Already at target
    return
  end

  -- Normalize direction
  directionX = directionX / distance
  directionY = directionY / distance

  -- Get entity's movement speed from stats
  local speedStat = EntityManager:getComponent(entity, ComponentType.SPEEDSTAT)
  local baseSpeed = speedStat or constants.DEFAULT_MOVEMENT_SPEED or 1.0

  -- Apply topography speed modifier
  local currentTileEntity = self:getCurrentTileEntity(position)
  local speedMultiplier = 1.0
  if currentTileEntity then
    local topography = EntityManager:getComponent(currentTileEntity, ComponentType.TOPOGRAPHY)
    if topography then
      speedMultiplier = topography.speedMultiplier or 1.0
    end
  end

  -- Calculate final movement speed
  local finalSpeed = baseSpeed * speedModifier * speedMultiplier / constants.TICKSPEED

  -- Calculate movement step
  local stepX = directionX * finalSpeed * dt
  local stepY = directionY * finalSpeed * dt
  local stepDistance = math.sqrt(stepX * stepX + stepY * stepY)

  -- Calculate proposed new position
  local newX, newY
  if stepDistance >= distance then
    -- Would overshoot target, move directly to target
    newX = target.x
    newY = target.y
  else
    -- Normal movement step
    newX = position.x + stepX
    newY = position.y + stepY
  end

  -- Validate movement (collision detection)
  if self:isValidMovement(position, Vec2.new(newX, newY)) then
    -- Movement is valid, update position
    position.x = newX
    position.y = newY
    if velocity then
      if stepDistance >= distance then
        velocity.x = 0
        velocity.y = 0
      else
        velocity.x = stepX / dt
        velocity.y = stepY / dt
      end
    end
  else
    -- Movement blocked, stop entity
    if velocity then
      velocity.x = 0
      velocity.y = 0
    end
    Logger:debug("MovementSystem: Movement blocked for entity " .. entity .. " at (" .. position.x .. "," .. position.y .. ")")
  end
end

--- Gets the current tile entity for position-based calculations
---@param position Vec2 Current position
---@return number? Tile entity ID or nil if not found
function MovementSystem:getCurrentTileEntity(position)
  local intX = math.floor(position.x + 0.5)
  local intY = math.floor(position.y + 0.5)
  local tilePosition = Vec2.new(intX, intY)
  
  return EntityManager:find(ComponentType.MAPTILE_TAG, tilePosition)
end

--- Generates a path for the movement task using existing pathfinding with spatial optimization
---@param entity number Entity ID
---@param movementTask MovementTask Movement task component
---@param position Vec2 Current position
---@return boolean True if path was successfully generated
function MovementSystem:generatePath(entity, movementTask, position)
  if not movementTask.targetPosition then
    Logger:error("MovementSystem: No target position set for movement task")
    return false
  end

  -- Use spatial index to check for nearby obstacles or alternative routes
  local nearbyEntities = self.spatialIndex:getNearbyEntities(position.x, position.y, 5.0)
  local congestionLevel = #nearbyEntities
  
  -- Try to use the existing PathFinder system for complex pathfinding
  local PathFinder = require("game.systems.PathFinder")
  local pathfinder = PathFinder.new()

  -- Use pathfinding to find optimal route
  local pathResult = pathfinder:findPath(position, movementTask.targetPosition)

  if pathResult and #pathResult > 0 then
    -- PathFinder returns grid positions, prepend current position for complete path
    local fullPath = { Vec2.new(position.x, position.y) }
    for _, gridPos in ipairs(pathResult) do
      table.insert(fullPath, Vec2.new(gridPos.x, gridPos.y))
    end
    movementTask:setPath(fullPath)
    Logger:debug("MovementSystem: Generated complex path with " .. #fullPath .. " waypoints (congestion: " .. congestionLevel .. ")")
    return true
  else
    -- Fallback to direct path if pathfinding fails
    Logger:debug("MovementSystem: Pathfinding failed, using direct path")
    local directPath = {
      Vec2.new(position.x, position.y), -- Start position
      Vec2.new(movementTask.targetPosition.x, movementTask.targetPosition.y) -- End position
    }
    movementTask:setPath(directPath)
    return true
  end
end

--- Completes movement and cleans up components
---@param entity number Entity ID
---@param movementTask MovementTask Completed movement task
---@param velocity Vec2? Velocity component
function MovementSystem:completeMovement(entity, movementTask, velocity)
  -- Stop entity movement
  if velocity then
    velocity.x = 0
    velocity.y = 0
  end
  
  -- Remove the MovementTask component
  EntityManager:removeComponent(entity, ComponentType.MOVEMENT_TASK)
  
  -- Return task component to pool if it's poolable
  if movementTask._poolable then
    local TaskComponentPool = require("game.systems.TaskComponentPool")
    TaskComponentPool:release(movementTask, ComponentType.MOVEMENT_TASK)
  end
  
  Logger:debug("MovementSystem: Completed movement for entity " .. entity)
end

--- Gets performance statistics for the last update
---@return table Performance stats
function MovementSystem:getStats()
  local baseStats = {
    processedEntities = self.processedEntities,
    completedMovements = self.completedMovements,
    waypointThreshold = self.waypointThreshold
  }
  
  -- Add spatial indexing stats
  local spatialStats = self.spatialIndex:getStatistics()
  baseStats.spatial = spatialStats
  
  -- Add performance monitoring stats
  local perfSummary = self.performanceMonitor:getPerformanceSummary()
  baseStats.performance = perfSummary
  
  return baseStats
end

--- Updates system configuration
---@param config table Configuration options
function MovementSystem:configure(config)
  if config.movementSpeed then
    self.movementSpeed = config.movementSpeed
  end
  if config.waypointThreshold then
    self.waypointThreshold = config.waypointThreshold
  end
end

--- Finds all entities with MovementTask components
---@return number[] Array of entity IDs with movement tasks
function MovementSystem:findMovingEntities()
  local movingEntities = {}
  
  -- Query all entities with MovementTask components
  for entity, _ in pairs(EntityManager.entities) do
    local movementTask = EntityManager:getComponent(entity, ComponentType.MOVEMENT_TASK)
    if movementTask and not movementTask.isComplete then
      table.insert(movingEntities, entity)
    end
  end
  
  return movingEntities
end

--- Main update function for integration with game loop
---@param dt number Delta time
function MovementSystem:update(dt)
  -- Start frame monitoring
  local frameStartTime = self.performanceMonitor:startFrame()
  
  local movingEntities = self:findMovingEntities()
  self:processBatch(movingEntities, dt)
  
  -- Update spatial indexing performance metrics
  local spatialStats = self.spatialIndex:getStatistics()
  self.performanceMonitor:recordSpatialMetrics(
    spatialStats.queriesThisFrame,
    spatialStats.averageQueryTime,
    spatialStats.entitiesTracked,
    spatialStats.gridCells
  )
  
  -- Reset frame stats for next frame
  self.spatialIndex:resetFrameStats()
  
  -- End frame monitoring
  self.performanceMonitor:endFrame(frameStartTime, self.processedEntities)
end

--- Sorts entities by spatial proximity for cache-friendly batch processing
---@param entities number[] Array of entity IDs to sort
function MovementSystem:sortEntitiesByProximity(entities)
  if #entities <= 1 then
    return
  end
  
  -- Get positions for all entities
  local entityPositions = {}
  for _, entity in ipairs(entities) do
    local position = EntityManager:getComponent(entity, ComponentType.POSITION)
    if position then
      entityPositions[entity] = { x = position.x, y = position.y }
    end
  end
  
  -- Sort by spatial locality using Z-order (Morton order) for better cache performance
  table.sort(entities, function(a, b)
    local posA = entityPositions[a]
    local posB = entityPositions[b]
    
    if not posA or not posB then
      return false
    end
    
    -- Convert to grid coordinates for sorting
    local gridAX, gridAY = self.spatialIndex:worldToGrid(posA.x, posA.y)
    local gridBX, gridBY = self.spatialIndex:worldToGrid(posB.x, posB.y)
    
    -- Calculate Z-order (Morton order) for spatial locality
    local function morton(x, y)
      local result = 0
      for i = 0, 15 do
        result = result + (bit.lshift(bit.band(x, bit.lshift(1, i)), i) + bit.lshift(bit.band(y, bit.lshift(1, i)), i + 1))
      end
      return result
    end
    
    -- Fallback to simple comparison if bit operations not available
    if not bit or not bit.lshift then
      return gridAX + gridAY * 1000 < gridBX + gridBY * 1000
    end
    
    return morton(gridAX, gridAY) < morton(gridBX, gridBY)
  end)
end

--- Gets enhanced performance statistics including spatial metrics
---@return table Performance stats with spatial data
function MovementSystem:getStats()
  local baseStats = {
    processedEntities = self.processedEntities,
    completedMovements = self.completedMovements,
    waypointThreshold = self.waypointThreshold
  }
  
  -- Add spatial indexing stats
  local spatialStats = self.spatialIndex:getStatistics()
  baseStats.spatial = spatialStats
  
  -- Add performance monitoring stats
  local perfSummary = self.performanceMonitor:getPerformanceSummary()
  baseStats.performance = perfSummary
  
  return baseStats
end

--- Validates if movement from one position to another is allowed
---@param fromPos Vec2 Starting position
---@param toPos Vec2 Target position
---@return boolean True if movement is valid
function MovementSystem:isValidMovement(fromPos, toPos)
  -- Get the tile entity at the target position
  local targetTileEntity = self:getCurrentTileEntity(toPos)
  if not targetTileEntity then
    -- No tile found, movement blocked
    return false
  end

  -- Check topography for passability
  local topography = EntityManager:getComponent(targetTileEntity, ComponentType.TOPOGRAPHY)
  if topography then
    -- Check if tile is impassable (speedMultiplier <= 0)
    if not topography.speedMultiplier or topography.speedMultiplier <= 0 then
      return false
    end

    -- Check for specific topography types that block movement
    local TopographyType = require("game.utils.enums").TopographyType
    if topography.type == TopographyType.INACCESSIBLE then
      return false
    end
  end

  -- TODO: Add entity-to-entity collision detection here if needed
  -- This would check if other entities are occupying the target position

  return true
end

--- Checks if a position is within map bounds
---@param position Vec2 Position to check
---@return boolean True if position is within bounds
function MovementSystem:isInBounds(position)
  -- Check if MapManager exists and has valid bounds
  if not MapManager or not MapManager.width or not MapManager.height then
    Logger:error("MovementSystem: MapManager not available for bounds checking")
    return false
  end

  local x = math.floor(position.x + 0.5)
  local y = math.floor(position.y + 0.5)

  return x >= 1 and x <= MapManager.width and y >= 1 and y <= MapManager.height
end

--- Finds the nearest passable position to a target (used when target is blocked)
---@param targetPos Vec2 Blocked target position
---@param maxRadius number Maximum search radius
---@return Vec2? Nearest passable position or nil if none found
function MovementSystem:findNearestPassablePosition(targetPos, maxRadius)
  maxRadius = maxRadius or 5

  -- Check if target is already passable
  if self:isValidMovement(targetPos, targetPos) then
    return targetPos
  end

  -- Spiral search pattern to find nearest passable position
  for radius = 1, maxRadius do
    for dx = -radius, radius do
      for dy = -radius, radius do
        -- Only check positions on the edge of the current radius
        if math.abs(dx) == radius or math.abs(dy) == radius then
          local testPos = Vec2.new(targetPos.x + dx, targetPos.y + dy)

          if self:isInBounds(testPos) and self:isValidMovement(testPos, testPos) then
            return testPos
          end
        end
      end
    end
  end

  return nil
end

--- Sorts entities by spatial proximity for cache-friendly batch processing
---@param entities number[] Array of entity IDs to sort
function MovementSystem:sortEntitiesByProximity(entities)
  if #entities <= 1 then
    return
  end
  
  -- Get positions for all entities
  local entityPositions = {}
  for _, entity in ipairs(entities) do
    local position = EntityManager:getComponent(entity, ComponentType.POSITION)
    if position then
      entityPositions[entity] = { x = position.x, y = position.y }
    end
  end
  
  -- Sort by spatial locality for better cache performance
  table.sort(entities, function(a, b)
    local posA = entityPositions[a]
    local posB = entityPositions[b]
    
    if not posA or not posB then
      return false
    end
    
    -- Convert to grid coordinates for sorting
    local gridAX, gridAY = self.spatialIndex:worldToGrid(posA.x, posA.y)
    local gridBX, gridBY = self.spatialIndex:worldToGrid(posB.x, posB.y)
    
    -- Simple spatial sorting by grid position
    return gridAX + gridAY * 1000 < gridBX + gridBY * 1000
  end)
end

--- Process method for TaskExecutionSystem integration
--- This method is called by TaskExecutionSystem for each entity with a MovementTask
---@param entityId number Entity ID to process
---@param movementTask MovementTask Movement task component
---@param dt number Delta time
---@return boolean Success status
function MovementSystem:process(entityId, movementTask, dt)
  if not movementTask or movementTask.isComplete then
    return true
  end

  local position = EntityManager:getComponent(entityId, ComponentType.POSITION)
  local velocity = EntityManager:getComponent(entityId, ComponentType.VELOCITY)

  if not position then
    Logger:error("MovementSystem: Entity " .. entityId .. " has MovementTask but no Position component")
    return false
  end

  -- Process movement for this entity
  local wasCompleted = self:updateMovement(entityId, movementTask, position, velocity, dt)
  return true
end

--- Registers this MovementSystem as a processor with TaskExecutionSystem
---@param taskExecutionSystem TaskExecutionSystem The system to register with
---@return boolean Success status
function MovementSystem:registerWithTaskExecutionSystem(taskExecutionSystem)
  if not taskExecutionSystem then
    Logger:error("MovementSystem: Invalid TaskExecutionSystem provided")
    return false
  end

  local success = taskExecutionSystem:registerProcessor(ComponentType.MOVEMENT_TASK, self)
  if success then
    Logger:info("MovementSystem: Successfully registered with TaskExecutionSystem")
  else
    Logger:error("MovementSystem: Failed to register with TaskExecutionSystem")
  end

  return success
end

return MovementSystem