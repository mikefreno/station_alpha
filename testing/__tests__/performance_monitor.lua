-- Unit tests for PerformanceMonitor system
-- Tests correctness of performance monitoring functionality

require("testing.loveStub")
local luaunit = require("testing.luaunit")

local PerformanceMonitor = require("game.systems.PerformanceMonitor")

local TestPerformanceMonitor = {}

function TestPerformanceMonitor:setUp()
  self.performanceMonitor = PerformanceMonitor:new()
end

function TestPerformanceMonitor:tearDown()
  self.performanceMonitor = nil
end

-- Test basic frame time tracking
function TestPerformanceMonitor:testFrameTimeTracking()
  self.performanceMonitor:startFrame()

  -- Simulate some processing time
  love.timer.sleep(0.001) -- 1ms

  self.performanceMonitor:endFrame()

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertNotNil(stats.frame_time)
  luaunit.assertTrue(stats.frame_time.current > 0)
  luaunit.assertTrue(stats.frame_time.average > 0)
end

-- Test task performance recording
function TestPerformanceMonitor:testTaskPerformanceRecording()
  local taskType = "movement"
  local entityCount = 10
  local processingTime = 0.005 -- 5ms

  self.performanceMonitor:recordTaskPerformance(taskType, entityCount, processingTime)

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertNotNil(stats.task_performance)
  luaunit.assertNotNil(stats.task_performance[taskType])
  luaunit.assertEqual(stats.task_performance[taskType].total_processed, entityCount)
  luaunit.assertTrue(stats.task_performance[taskType].total_time >= processingTime)
end

-- Test memory monitoring
function TestPerformanceMonitor:testMemoryMonitoring()
  self.performanceMonitor:startFrame()

  -- Force some memory allocation
  local testData = {}
  for i = 1, 1000 do
    testData[i] = string.rep("test", 100)
  end

  self.performanceMonitor:endFrame()

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertNotNil(stats.memory)
  luaunit.assertTrue(stats.memory.current > 0)
  luaunit.assertNotNil(stats.memory.trend)
end

-- Test multiple frame tracking
function TestPerformanceMonitor:testMultipleFrameTracking()
  -- Track multiple frames
  for i = 1, 10 do
    self.performanceMonitor:startFrame()
    love.timer.sleep(0.001)
    self.performanceMonitor:endFrame()
  end

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertTrue(stats.frame_time.frame_count >= 10)
  luaunit.assertTrue(stats.frame_time.peak > 0)
  luaunit.assertTrue(stats.frame_time.average > 0)
end

-- Test performance reset functionality
function TestPerformanceMonitor:testPerformanceReset()
  -- Record some data
  self.performanceMonitor:recordTaskPerformance("test", 5, 0.001)
  self.performanceMonitor:startFrame()
  self.performanceMonitor:endFrame()

  -- Reset performance data
  self.performanceMonitor:reset()

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertEqual(stats.frame_time.frame_count, 0)
  luaunit.assertEqual(stats.frame_time.current, 0)
  
  -- Task performance should be reset
  luaunit.assertTrue(not stats.task_performance.test or 
                    stats.task_performance.test.total_processed == 0)
end

-- Test spatial index performance tracking
function TestPerformanceMonitor:testSpatialIndexPerformance()
  local queryTime = 0.002 -- 2ms
  local entitiesFound = 15
  local gridSize = 8

  self.performanceMonitor:recordSpatialIndexPerformance(queryTime, entitiesFound, gridSize)

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertNotNil(stats.spatial_index)
  luaunit.assertTrue(stats.spatial_index.total_queries > 0)
  luaunit.assertTrue(stats.spatial_index.total_query_time >= queryTime)
  luaunit.assertTrue(stats.spatial_index.total_entities_found >= entitiesFound)
end

-- Test system performance tracking
function TestPerformanceMonitor:testSystemPerformance()
  local systemName = "MovementSystem"
  local processingTime = 0.003 -- 3ms

  self.performanceMonitor:recordSystemPerformance(systemName, processingTime)

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertNotNil(stats.system_performance)
  luaunit.assertNotNil(stats.system_performance[systemName])
  luaunit.assertTrue(stats.system_performance[systemName].total_time >= processingTime)
  luaunit.assertTrue(stats.system_performance[systemName].call_count > 0)
end

-- Test performance threshold warnings
function TestPerformanceMonitor:testPerformanceThresholds()
  -- Record a slow frame
  self.performanceMonitor:startFrame()
  love.timer.sleep(0.020) -- 20ms (over 16.67ms for 60fps)
  self.performanceMonitor:endFrame()

  local stats = self.performanceMonitor:getStatistics()
  
  -- Should detect slow frame
  luaunit.assertTrue(stats.frame_time.current > 0.016)
  
  -- Check if warnings are tracked
  local warnings = self.performanceMonitor:getWarnings()
  luaunit.assertNotNil(warnings)
end

-- Test batch processing efficiency calculation
function TestPerformanceMonitor:testBatchProcessingEfficiency()
  -- Record batch processing
  self.performanceMonitor:recordTaskPerformance("mining", 50, 0.010) -- 50 entities in 10ms
  self.performanceMonitor:recordTaskPerformance("mining", 25, 0.008) -- 25 entities in 8ms

  local stats = self.performanceMonitor:getStatistics()
  local miningStats = stats.task_performance.mining

  luaunit.assertNotNil(miningStats)
  luaunit.assertEqual(miningStats.total_processed, 75)
  luaunit.assertTrue(miningStats.efficiency > 0) -- entities per second
end

-- Test memory trend analysis
function TestPerformanceMonitor:testMemoryTrendAnalysis()
  -- Simulate memory increase over multiple frames
  for i = 1, 5 do
    self.performanceMonitor:startFrame()
    
    -- Allocate increasing amounts of memory
    local data = {}
    for j = 1, i * 100 do
      data[j] = {}
    end
    
    self.performanceMonitor:endFrame()
  end

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertNotNil(stats.memory.trend)
  
  -- Trend should be "rising", "falling", or "stable"
  luaunit.assertTrue(stats.memory.trend == "rising" or 
                    stats.memory.trend == "falling" or 
                    stats.memory.trend == "stable")
end

-- Test configuration settings
function TestPerformanceMonitor:testConfigurationSettings()
  local config = {
    frame_history_size = 50,
    memory_check_interval = 30,
    enable_detailed_tracking = false
  }

  local monitor = PerformanceMonitor:new(config)
  luaunit.assertNotNil(monitor)

  -- Test that configuration is applied
  monitor:startFrame()
  monitor:endFrame()

  local stats = monitor:getStatistics()
  luaunit.assertNotNil(stats)
end

-- Test garbage collection monitoring
function TestPerformanceMonitor:testGarbageCollectionMonitoring()
  self.performanceMonitor:startFrame()
  
  -- Force garbage collection
  collectgarbage("collect")
  
  self.performanceMonitor:endFrame()

  local stats = self.performanceMonitor:getStatistics()
  luaunit.assertNotNil(stats.gc)
  luaunit.assertTrue(stats.gc.collections >= 0)
end

-- Run all tests
os.exit(luaunit.LuaUnit.run())