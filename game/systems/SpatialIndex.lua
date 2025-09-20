local Logger = require("logger")

-- High-performance spatial indexing system for fast proximity queries
-- Uses a grid-based approach to achieve O(1) average case lookup times
-- @type SpatialIndex
local SpatialIndex = {
  gridSize = 8, -- Grid cell size in tiles (configurable)
  grid = {}, -- 2D grid of entity lists [x][y] = {entityId1, entityId2, ...}
  entityPositions = {}, -- Cache of entity positions for fast updates
  entityGridPos = {}, -- Cache of entity grid positions {entityId = {x, y}}
  statistics = {
    gridCells = 0,
    entitiesTracked = 0,
    queriesThisFrame = 0,
    averageQueryTime = 0,
  },
  isInitialized = false,
}

-- Initialize the spatial index system
function SpatialIndex:init()
  if self.isInitialized then
    Logger:warn("SpatialIndex already initialized")
    return
  end

  self.grid = {}
  self.entityPositions = {}
  self.entityGridPos = {}
  self.statistics = {
    gridCells = 0,
    entitiesTracked = 0,
    queriesThisFrame = 0,
    averageQueryTime = 0,
  }

  self.isInitialized = true
  Logger:info("SpatialIndex initialized with grid size: " .. self.gridSize)
end

-- Convert world position to grid coordinates
-- @param x number World X coordinate
-- @param y number World Y coordinate
-- @return number, number Grid X and Y coordinates
function SpatialIndex:worldToGrid(x, y)
  return math.floor(x / self.gridSize), math.floor(y / self.gridSize)
end

-- Get or create grid cell at coordinates
-- @param gridX number Grid X coordinate
-- @param gridY number Grid Y coordinate
-- @return table List of entities in this cell
function SpatialIndex:getGridCell(gridX, gridY)
  if not self.grid[gridX] then
    self.grid[gridX] = {}
    self.statistics.gridCells = self.statistics.gridCells + 1
  end
  if not self.grid[gridX][gridY] then
    self.grid[gridX][gridY] = {}
  end
  return self.grid[gridX][gridY]
end

-- Add entity to spatial index
-- @param entityId number The entity ID to track
-- @param x number World X position
-- @param y number World Y position
function SpatialIndex:addEntity(entityId, x, y)
  if not self.isInitialized then
    Logger:error("SpatialIndex not initialized")
    return false
  end

  local gridX, gridY = self:worldToGrid(x, y)
  local cell = self:getGridCell(gridX, gridY)

  -- Add to grid cell
  table.insert(cell, entityId)

  -- Cache position and grid location
  self.entityPositions[entityId] = { x = x, y = y }
  self.entityGridPos[entityId] = { x = gridX, y = gridY }

  self.statistics.entitiesTracked = self.statistics.entitiesTracked + 1
  return true
end

-- Remove entity from spatial index
-- @param entityId number The entity ID to stop tracking
function SpatialIndex:removeEntity(entityId)
  if not self.isInitialized then
    Logger:error("SpatialIndex not initialized")
    return false
  end

  local gridPos = self.entityGridPos[entityId]
  if not gridPos then
    return false -- Entity not tracked
  end

  -- Remove from grid cell
  local cell = self:getGridCell(gridPos.x, gridPos.y)
  for i, id in ipairs(cell) do
    if id == entityId then
      table.remove(cell, i)
      break
    end
  end

  -- Clear cache
  self.entityPositions[entityId] = nil
  self.entityGridPos[entityId] = nil

  self.statistics.entitiesTracked = self.statistics.entitiesTracked - 1
  return true
end

-- Update entity position in spatial index
-- @param entityId number The entity ID to update
-- @param newX number New world X position
-- @param newY number New world Y position
function SpatialIndex:updateEntity(entityId, newX, newY)
  if not self.isInitialized then
    Logger:error("SpatialIndex not initialized")
    return false
  end

  local oldPos = self.entityPositions[entityId]
  if not oldPos then
    -- Entity not tracked, add it
    return self:addEntity(entityId, newX, newY)
  end

  local oldGridX, oldGridY = self:worldToGrid(oldPos.x, oldPos.y)
  local newGridX, newGridY = self:worldToGrid(newX, newY)

  -- If grid position changed, update grid
  if oldGridX ~= newGridX or oldGridY ~= newGridY then
    -- Remove from old cell
    local oldCell = self:getGridCell(oldGridX, oldGridY)
    for i, id in ipairs(oldCell) do
      if id == entityId then
        table.remove(oldCell, i)
        break
      end
    end

    -- Add to new cell
    local newCell = self:getGridCell(newGridX, newGridY)
    table.insert(newCell, entityId)

    -- Update cached grid position
    self.entityGridPos[entityId] = { x = newGridX, y = newGridY }
  end

  -- Update cached position
  self.entityPositions[entityId] = { x = newX, y = newY }
  return true
end

-- Get entities within radius of a position
-- @param x number Center X position
-- @param y number Center Y position
-- @param radius number Search radius
-- @return table List of entity IDs within radius
function SpatialIndex:getNearbyEntities(x, y, radius)
  if not self.isInitialized then
    Logger:error("SpatialIndex not initialized")
    return {}
  end

  local startTime = love.timer.getTime()
  local results = {}
  local radiusSquared = radius * radius

  -- Calculate grid range to check
  local minGridX, minGridY = self:worldToGrid(x - radius, y - radius)
  local maxGridX, maxGridY = self:worldToGrid(x + radius, y + radius)

  -- Check all grid cells in range
  for gridX = minGridX, maxGridX do
    if self.grid[gridX] then
      for gridY = minGridY, maxGridY do
        local cell = self.grid[gridX][gridY]
        if cell then
          -- Check each entity in cell
          for _, entityId in ipairs(cell) do
            local entityPos = self.entityPositions[entityId]
            if entityPos then
              local dx = entityPos.x - x
              local dy = entityPos.y - y
              local distanceSquared = dx * dx + dy * dy

              if distanceSquared <= radiusSquared then
                table.insert(results, entityId)
              end
            end
          end
        end
      end
    end
  end

  -- Update performance statistics
  local queryTime = love.timer.getTime() - startTime
  self.statistics.queriesThisFrame = self.statistics.queriesThisFrame + 1
  self.statistics.averageQueryTime = (self.statistics.averageQueryTime + queryTime) / 2

  return results
end

-- Get entities in a rectangular area
-- @param minX number Minimum X coordinate
-- @param minY number Minimum Y coordinate
-- @param maxX number Maximum X coordinate
-- @param maxY number Maximum Y coordinate
-- @return table List of entity IDs in rectangle
function SpatialIndex:getEntitiesInRect(minX, minY, maxX, maxY)
  if not self.isInitialized then
    Logger:error("SpatialIndex not initialized")
    return {}
  end

  local results = {}

  -- Calculate grid range
  local minGridX, minGridY = self:worldToGrid(minX, minY)
  local maxGridX, maxGridY = self:worldToGrid(maxX, maxY)

  -- Check all grid cells in range
  for gridX = minGridX, maxGridX do
    if self.grid[gridX] then
      for gridY = minGridY, maxGridY do
        local cell = self.grid[gridX][gridY]
        if cell then
          for _, entityId in ipairs(cell) do
            local entityPos = self.entityPositions[entityId]
            if
              entityPos
              and entityPos.x >= minX
              and entityPos.x <= maxX
              and entityPos.y >= minY
              and entityPos.y <= maxY
            then
              table.insert(results, entityId)
            end
          end
        end
      end
    end
  end

  return results
end

-- Get the closest entity to a position within radius
-- @param x number Center X position
-- @param y number Center Y position
-- @param radius number Search radius
-- @param filterFunc function Optional filter function(entityId) -> boolean
-- @return number|nil Entity ID of closest entity, or nil if none found
function SpatialIndex:getClosestEntity(x, y, radius, filterFunc)
  local entities = self:getNearbyEntities(x, y, radius)
  local closestEntity = nil
  local closestDistance = radius * radius

  for _, entityId in ipairs(entities) do
    if not filterFunc or filterFunc(entityId) then
      local entityPos = self.entityPositions[entityId]
      if entityPos then
        local dx = entityPos.x - x
        local dy = entityPos.y - y
        local distanceSquared = dx * dx + dy * dy

        if distanceSquared < closestDistance then
          closestDistance = distanceSquared
          closestEntity = entityId
        end
      end
    end
  end

  return closestEntity
end

-- Optimize grid by removing empty cells
-- Call this periodically to prevent memory leaks
function SpatialIndex:optimizeGrid()
  local removedCells = 0

  for gridX, column in pairs(self.grid) do
    for gridY, cell in pairs(column) do
      if #cell == 0 then
        column[gridY] = nil
        removedCells = removedCells + 1
      end
    end

    -- Remove empty columns
    local hasAnyCells = false
    for _ in pairs(column) do
      hasAnyCells = true
      break
    end
    if not hasAnyCells then
      self.grid[gridX] = nil
    end
  end

  self.statistics.gridCells = self.statistics.gridCells - removedCells
  Logger:debug("Optimized spatial grid, removed " .. removedCells .. " empty cells")
end

-- Reset frame statistics (call at start of each frame)
function SpatialIndex:resetFrameStats()
  self.statistics.queriesThisFrame = 0
  self.statistics.averageQueryTime = 0
end

-- Get performance statistics
-- @return table Current performance statistics
function SpatialIndex:getStatistics()
  return {
    gridCells = self.statistics.gridCells,
    entitiesTracked = self.statistics.entitiesTracked,
    queriesThisFrame = self.statistics.queriesThisFrame,
    averageQueryTime = self.statistics.averageQueryTime,
    gridSize = self.gridSize,
  }
end

-- Configure grid size (must be called before adding entities)
-- @param size number New grid size in world units
function SpatialIndex:setGridSize(size)
  if self.statistics.entitiesTracked > 0 then
    Logger:warn("Cannot change grid size while entities are tracked")
    return false
  end

  self.gridSize = size
  Logger:info("Set spatial index grid size to: " .. size)
  return true
end

return SpatialIndex