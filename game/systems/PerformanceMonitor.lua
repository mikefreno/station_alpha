local Logger = require("logger")

-- High-performance monitoring system for tracking task execution metrics
-- Provides detailed performance data for optimization and debugging
-- @type PerformanceMonitor
local PerformanceMonitor = {
  taskMetrics = {}, -- Per-task-type performance data {[ComponentType] = {metrics}}
  frameTimeHistory = {}, -- Rolling window of recent frame times
  memoryUsage = {}, -- Memory allocation tracking
  spatialMetrics = {}, -- Spatial indexing performance data
  systemMetrics = {}, -- Per-system performance tracking
  configuration = {
    historySize = 100, -- Number of frames to track
    enableMemoryTracking = true,
    enableSpatialTracking = true,
    enableDetailedProfiling = false,
  },
  statistics = {
    totalFrames = 0,
    averageFrameTime = 0,
    peakFrameTime = 0,
    memoryPeak = 0,
    tasksProcessedTotal = 0,
  },
  isInitialized = false,
}

-- Initialize the performance monitoring system
function PerformanceMonitor:init()
  if self.isInitialized then
    Logger:warn("PerformanceMonitor already initialized")
    return
  end

  self.taskMetrics = {}
  self.frameTimeHistory = {}
  self.memoryUsage = {}
  self.spatialMetrics = {}
  self.systemMetrics = {}

  self.statistics = {
    totalFrames = 0,
    averageFrameTime = 0,
    peakFrameTime = 0,
    memoryPeak = 0,
    tasksProcessedTotal = 0,
  }

  self.isInitialized = true
  Logger:info("PerformanceMonitor initialized")
end

-- Start monitoring a frame
-- @return number Frame start timestamp
function PerformanceMonitor:startFrame()
  if not self.isInitialized then
    return 0
  end

  local frameStartTime = love.timer.getTime()

  -- Track memory usage if enabled
  if self.configuration.enableMemoryTracking then
    local memoryKB = collectgarbage("count")
    table.insert(self.memoryUsage, {
      timestamp = frameStartTime,
      memory = memoryKB,
    })

    -- Keep memory history limited
    if #self.memoryUsage > self.configuration.historySize then
      table.remove(self.memoryUsage, 1)
    end

    -- Update memory peak
    if memoryKB > self.statistics.memoryPeak then
      self.statistics.memoryPeak = memoryKB
    end
  end

  return frameStartTime
end

-- End monitoring a frame and update statistics
-- @param frameStartTime number Timestamp from startFrame()
-- @param tasksProcessed number Number of tasks processed this frame
function PerformanceMonitor:endFrame(frameStartTime, tasksProcessed)
  if not self.isInitialized or frameStartTime == 0 then
    return
  end

  local frameTime = love.timer.getTime() - frameStartTime
  tasksProcessed = tasksProcessed or 0

  -- Add to frame time history
  table.insert(self.frameTimeHistory, frameTime)
  if #self.frameTimeHistory > self.configuration.historySize then
    table.remove(self.frameTimeHistory, 1)
  end

  -- Update statistics
  self.statistics.totalFrames = self.statistics.totalFrames + 1
  self.statistics.tasksProcessedTotal = self.statistics.tasksProcessedTotal + tasksProcessed

  -- Update peak frame time
  if frameTime > self.statistics.peakFrameTime then
    self.statistics.peakFrameTime = frameTime
  end

  -- Calculate rolling average frame time
  local totalTime = 0
  for _, time in ipairs(self.frameTimeHistory) do
    totalTime = totalTime + time
  end
  self.statistics.averageFrameTime = totalTime / #self.frameTimeHistory
end

-- Record task processing metrics
-- @param componentType number The task component type
-- @param processingTime number Time taken to process (seconds)
-- @param tasksProcessed number Number of tasks processed
-- @param batchSize number Size of the batch processed
function PerformanceMonitor:recordTaskMetrics(componentType, processingTime, tasksProcessed, batchSize)
  if not self.isInitialized then
    return
  end

  if not self.taskMetrics[componentType] then
    self.taskMetrics[componentType] = {
      totalTime = 0,
      totalTasks = 0,
      totalBatches = 0,
      averageTime = 0,
      averageBatchSize = 0,
      peakTime = 0,
      peakBatchSize = 0,
      history = {},
    }
  end

  local metrics = self.taskMetrics[componentType]
  tasksProcessed = tasksProcessed or 0
  batchSize = batchSize or tasksProcessed

  -- Update totals
  metrics.totalTime = metrics.totalTime + processingTime
  metrics.totalTasks = metrics.totalTasks + tasksProcessed
  metrics.totalBatches = metrics.totalBatches + 1

  -- Update peaks
  if processingTime > metrics.peakTime then
    metrics.peakTime = processingTime
  end
  if batchSize > metrics.peakBatchSize then
    metrics.peakBatchSize = batchSize
  end

  -- Calculate averages
  metrics.averageTime = metrics.totalTime / metrics.totalBatches
  metrics.averageBatchSize = metrics.totalTasks / metrics.totalBatches

  -- Add to history
  table.insert(metrics.history, {
    timestamp = love.timer.getTime(),
    processingTime = processingTime,
    tasksProcessed = tasksProcessed,
    batchSize = batchSize,
  })

  -- Limit history size
  if #metrics.history > self.configuration.historySize then
    table.remove(metrics.history, 1)
  end
end

-- Record spatial indexing metrics
-- @param queriesThisFrame number Number of spatial queries
-- @param averageQueryTime number Average query time
-- @param entitiesTracked number Total entities being tracked
-- @param gridCells number Number of active grid cells
function PerformanceMonitor:recordSpatialMetrics(queriesThisFrame, averageQueryTime, entitiesTracked, gridCells)
  if not self.isInitialized or not self.configuration.enableSpatialTracking then
    return
  end

  table.insert(self.spatialMetrics, {
    timestamp = love.timer.getTime(),
    queries = queriesThisFrame,
    averageQueryTime = averageQueryTime,
    entitiesTracked = entitiesTracked,
    gridCells = gridCells,
  })

  -- Limit history size
  if #self.spatialMetrics > self.configuration.historySize then
    table.remove(self.spatialMetrics, 1)
  end
end

-- Record system-specific metrics
-- @param systemName string Name of the system
-- @param processingTime number Time taken by system (seconds)
-- @param entitiesProcessed number Number of entities processed
function PerformanceMonitor:recordSystemMetrics(systemName, processingTime, entitiesProcessed)
  if not self.isInitialized then
    return
  end

  if not self.systemMetrics[systemName] then
    self.systemMetrics[systemName] = {
      totalTime = 0,
      totalEntities = 0,
      totalRuns = 0,
      averageTime = 0,
      averageEntities = 0,
      peakTime = 0,
      peakEntities = 0,
    }
  end

  local metrics = self.systemMetrics[systemName]
  entitiesProcessed = entitiesProcessed or 0

  metrics.totalTime = metrics.totalTime + processingTime
  metrics.totalEntities = metrics.totalEntities + entitiesProcessed
  metrics.totalRuns = metrics.totalRuns + 1

  -- Update peaks
  if processingTime > metrics.peakTime then
    metrics.peakTime = processingTime
  end
  if entitiesProcessed > metrics.peakEntities then
    metrics.peakEntities = entitiesProcessed
  end

  -- Calculate averages
  metrics.averageTime = metrics.totalTime / metrics.totalRuns
  metrics.averageEntities = metrics.totalEntities / metrics.totalRuns
end

-- Get performance summary
-- @return table Complete performance statistics
function PerformanceMonitor:getPerformanceSummary()
  if not self.isInitialized then
    return {}
  end

  local summary = {
    frame = {
      totalFrames = self.statistics.totalFrames,
      averageFrameTime = self.statistics.averageFrameTime,
      peakFrameTime = self.statistics.peakFrameTime,
      currentFPS = self.statistics.averageFrameTime > 0 and (1 / self.statistics.averageFrameTime) or 0,
    },
    tasks = {
      totalProcessed = self.statistics.tasksProcessedTotal,
      averagePerFrame = self.statistics.totalFrames > 0
          and (self.statistics.tasksProcessedTotal / self.statistics.totalFrames)
        or 0,
      byType = {},
    },
    memory = {
      current = self.configuration.enableMemoryTracking and collectgarbage("count") or 0,
      peak = self.statistics.memoryPeak,
      trend = self:calculateMemoryTrend(),
    },
    spatial = self:getSpatialSummary(),
    systems = self.systemMetrics,
  }

  -- Add task type breakdowns
  for componentType, metrics in pairs(self.taskMetrics) do
    summary.tasks.byType[componentType] = {
      totalTasks = metrics.totalTasks,
      totalTime = metrics.totalTime,
      averageTime = metrics.averageTime,
      averageBatchSize = metrics.averageBatchSize,
      efficiency = metrics.totalTasks > 0 and (metrics.totalTasks / metrics.totalTime) or 0,
    }
  end

  return summary
end

-- Get spatial indexing performance summary
-- @return table Spatial performance metrics
function PerformanceMonitor:getSpatialSummary()
  if not self.configuration.enableSpatialTracking or #self.spatialMetrics == 0 then
    return {}
  end

  local totalQueries = 0
  local totalQueryTime = 0
  local averageEntities = 0
  local averageCells = 0

  for _, entry in ipairs(self.spatialMetrics) do
    totalQueries = totalQueries + entry.queries
    totalQueryTime = totalQueryTime + (entry.averageQueryTime * entry.queries)
    averageEntities = averageEntities + entry.entitiesTracked
    averageCells = averageCells + entry.gridCells
  end

  local entryCount = #self.spatialMetrics
  return {
    totalQueries = totalQueries,
    averageQueryTime = totalQueries > 0 and (totalQueryTime / totalQueries) or 0,
    averageEntities = averageEntities / entryCount,
    averageCells = averageCells / entryCount,
    efficiency = averageEntities > 0 and (totalQueries / averageEntities) or 0,
  }
end

-- Calculate memory usage trend
-- @return string "rising", "falling", or "stable"
function PerformanceMonitor:calculateMemoryTrend()
  if #self.memoryUsage < 10 then
    return "insufficient_data"
  end

  local recentEntries = {}
  local startIndex = math.max(1, #self.memoryUsage - 9)
  for i = startIndex, #self.memoryUsage do
    table.insert(recentEntries, self.memoryUsage[i].memory)
  end

  local firstHalf = { table.unpack(recentEntries, 1, 5) }
  local secondHalf = { table.unpack(recentEntries, 6, 10) }

  local firstAvg = 0
  for _, mem in ipairs(firstHalf) do
    firstAvg = firstAvg + mem
  end
  firstAvg = firstAvg / #firstHalf

  local secondAvg = 0
  for _, mem in ipairs(secondHalf) do
    secondAvg = secondAvg + mem
  end
  secondAvg = secondAvg / #secondHalf

  local change = secondAvg - firstAvg
  local threshold = firstAvg * 0.02 -- 2% threshold

  if change > threshold then
    return "rising"
  elseif change < -threshold then
    return "falling"
  else
    return "stable"
  end
end

-- Get detailed profiling data for a specific task type
-- @param componentType number The task component type
-- @return table Detailed metrics for the task type
function PerformanceMonitor:getTaskTypeDetails(componentType)
  local metrics = self.taskMetrics[componentType]
  if not metrics then
    return nil
  end

  return {
    totalTasks = metrics.totalTasks,
    totalTime = metrics.totalTime,
    totalBatches = metrics.totalBatches,
    averageTime = metrics.averageTime,
    averageBatchSize = metrics.averageBatchSize,
    peakTime = metrics.peakTime,
    peakBatchSize = metrics.peakBatchSize,
    efficiency = metrics.totalTasks > 0 and (metrics.totalTasks / metrics.totalTime) or 0,
    history = metrics.history,
  }
end

-- Reset all performance statistics
function PerformanceMonitor:reset()
  self.taskMetrics = {}
  self.frameTimeHistory = {}
  self.memoryUsage = {}
  self.spatialMetrics = {}
  self.systemMetrics = {}

  self.statistics = {
    totalFrames = 0,
    averageFrameTime = 0,
    peakFrameTime = 0,
    memoryPeak = 0,
    tasksProcessedTotal = 0,
  }

  Logger:info("PerformanceMonitor statistics reset")
end

-- Configure monitoring settings
-- @param config table Configuration options
function PerformanceMonitor:configure(config)
  for key, value in pairs(config) do
    if self.configuration[key] ~= nil then
      self.configuration[key] = value
      Logger:debug("PerformanceMonitor configured: " .. key .. " = " .. tostring(value))
    end
  end
end

-- Force garbage collection and measure impact
-- @return table Before and after memory usage
function PerformanceMonitor:measureGarbageCollection()
  local beforeMemory = collectgarbage("count")
  local startTime = love.timer.getTime()

  collectgarbage("collect")

  local afterMemory = collectgarbage("count")
  local gcTime = love.timer.getTime() - startTime

  local result = {
    beforeMemory = beforeMemory,
    afterMemory = afterMemory,
    memoryFreed = beforeMemory - afterMemory,
    gcTime = gcTime,
  }

  Logger:debug(
    "Garbage collection freed " .. string.format("%.1f", result.memoryFreed) .. "KB in " .. string.format("%.3f", gcTime * 1000) .. "ms"
  )

  return result
end

return PerformanceMonitor