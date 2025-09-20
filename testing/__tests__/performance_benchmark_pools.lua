-- Performance Benchmark: Pooled vs Non-Pooled Task Component Creation
-- This benchmark demonstrates the performance improvements of object pooling
package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

-- Import love stub for timer functions
require("testing.loveStub")

-- Mock Logger for clean output (set BEFORE requiring other components)
local Logger = {
  debug = function(self, msg) end,
  info = function(self, msg)
    print("INFO: " .. tostring(msg))
  end,
  warn = function(self, msg)
    print("WARN: " .. tostring(msg))
  end,
  error = function(self, msg)
    print("ERROR: " .. tostring(msg))
  end,
  log = function(self, level, msg) end, -- Mock the log function that was causing issues
}
_G.Logger = Logger

-- Mock EntityManager
local EntityManager = {
  getComponent = function(entityId, componentType)
    return { x = 5, y = 5 }
  end,
}
_G.EntityManager = EntityManager

-- Import task components and pool
local Vec2 = require("game.utils.Vec2")
local TaskComponentPool = require("game.systems.TaskComponentPool")
local MovementTask = require("game.components.MovementTask")
local MiningTask = require("game.components.MiningTask")
local ConstructionTask = require("game.components.ConstructionTask")
local CleaningTask = require("game.components.CleaningTask")
local ComponentType = require("game.utils.enums").ComponentType
local ToolType = require("game.utils.enums").ToolType
local ResourceType = require("game.utils.enums").ResourceType

-- Benchmark configuration
local BENCHMARK_ITERATIONS = {
  small = 1000, -- 1K iterations for quick tests
  medium = 10000, -- 10K iterations for realistic workloads
  large = 50000, -- 50K iterations for stress testing
}

local function getTime()
  return love and love.timer and love.timer.getTime() or os.clock()
end

-- Utility function to collect garbage and measure memory
local function measureMemory()
  collectgarbage("collect")
  collectgarbage("collect") -- Call twice to ensure full collection
  return collectgarbage("count")
end

-- Performance measurement utility
local function measurePerformance(name, func, iterations)
  print(string.format("\n=== %s (%d iterations) ===", name, iterations))

  local memBefore = measureMemory()
  local startTime = getTime()

  func(iterations)

  local endTime = getTime()
  local memAfter = measureMemory()

  local duration = endTime - startTime
  local memoryUsed = memAfter - memBefore
  local operationsPerSecond = iterations / duration

  print(string.format("Duration: %.3f seconds", duration))
  print(string.format("Operations/sec: %.0f", operationsPerSecond))
  print(string.format("Memory used: %.2f KB", memoryUsed))
  print(string.format("Time per operation: %.6f seconds", duration / iterations))

  return {
    duration = duration,
    operationsPerSecond = operationsPerSecond,
    memoryUsed = memoryUsed,
    timePerOperation = duration / iterations,
  }
end

-- Non-pooled approach benchmarks
local function benchmarkNonPooledMovementTask(iterations)
  local tasks = {}
  for i = 1, iterations do
    local targetPos = Vec2.new(i % 100, (i * 2) % 100)
    local task = MovementTask.new(targetPos)
    tasks[i] = task
  end
  -- Tasks go out of scope and become garbage
end

local function benchmarkNonPooledMiningTask(iterations)
  local tasks = {}
  for i = 1, iterations do
    local task = MiningTask.new(i, 5, ToolType.PICKAXE, ResourceType.STONE)
    tasks[i] = task
  end
  -- Tasks go out of scope and become garbage
end

local function benchmarkNonPooledConstructionTask(iterations)
  local tasks = {}
  local materials = { [ResourceType.WOOD] = 5, [ResourceType.STONE] = 3 }
  for i = 1, iterations do
    local task = ConstructionTask.new(i, i + 1000, materials)
    tasks[i] = task
  end
  -- Tasks go out of scope and become garbage
end

local function benchmarkNonPooledCleaningTask(iterations)
  local tasks = {}
  for i = 1, iterations do
    local task = CleaningTask.new(Vec2.new(i % 50, (i * 3) % 50), 2.0, ToolType.BROOM)
    tasks[i] = task
  end
  -- Tasks go out of scope and become garbage
end

-- Pooled approach benchmarks
local function benchmarkPooledMovementTask(iterations)
  local tasks = {}
  for i = 1, iterations do
    local targetPos = Vec2.new(i % 100, (i * 2) % 100)
    local task = MovementTask.newFromPool(targetPos)
    tasks[i] = task
  end

  -- Release all tasks back to pool
  for _, task in ipairs(tasks) do
    TaskComponentPool:release(task, ComponentType.MOVEMENT_TASK)
  end
end

local function benchmarkPooledMiningTask(iterations)
  local tasks = {}
  for i = 1, iterations do
    local task = MiningTask.newFromPool(i, 5, ToolType.PICKAXE, ResourceType.STONE)
    tasks[i] = task
  end

  -- Release all tasks back to pool
  for _, task in ipairs(tasks) do
    TaskComponentPool:release(task, ComponentType.MINING_TASK)
  end
end

local function benchmarkPooledConstructionTask(iterations)
  local tasks = {}
  local materials = { [ResourceType.WOOD] = 5, [ResourceType.STONE] = 3 }
  for i = 1, iterations do
    local task = ConstructionTask.newFromPool(i, i + 1000, materials)
    tasks[i] = task
  end

  -- Release all tasks back to pool
  for _, task in ipairs(tasks) do
    TaskComponentPool:release(task, ComponentType.CONSTRUCTION_TASK)
  end
end

local function benchmarkPooledCleaningTask(iterations)
  local tasks = {}
  for i = 1, iterations do
    local task = CleaningTask.newFromPool(Vec2.new(i % 50, (i * 3) % 50), 2.0, ToolType.BROOM)
    tasks[i] = task
  end

  -- Release all tasks back to pool
  for _, task in ipairs(tasks) do
    TaskComponentPool:release(task, ComponentType.CLEANING_TASK)
  end
end

-- Mixed workload benchmarks (realistic usage patterns)
local function benchmarkNonPooledMixedWorkload(iterations)
  local tasks = {}
  local materials = { [ResourceType.WOOD] = 5, [ResourceType.STONE] = 3 }

  for i = 1, iterations do
    local taskType = i % 4
    local task

    if taskType == 0 then
      task = MovementTask.new(Vec2.new(i % 100, (i * 2) % 100))
    elseif taskType == 1 then
      task = MiningTask.new(i, 5, ToolType.PICKAXE, ResourceType.STONE)
    elseif taskType == 2 then
      task = ConstructionTask.new(i, i + 1000, materials)
    else
      task = CleaningTask.new(Vec2.new(i % 50, (i * 3) % 50), 2.0, ToolType.BROOM)
    end

    tasks[i] = task
  end
  -- Tasks go out of scope and become garbage
end

local function benchmarkPooledMixedWorkload(iterations)
  local tasks = {}
  local materials = { [ResourceType.WOOD] = 5, [ResourceType.STONE] = 3 }

  for i = 1, iterations do
    local taskType = i % 4
    local task

    if taskType == 0 then
      task = MovementTask.newFromPool(Vec2.new(i % 100, (i * 2) % 100))
    elseif taskType == 1 then
      task = MiningTask.newFromPool(i, 5, ToolType.PICKAXE, ResourceType.STONE)
    elseif taskType == 2 then
      task = ConstructionTask.newFromPool(i, i + 1000, materials)
    else
      task = CleaningTask.newFromPool(Vec2.new(i % 50, (i * 3) % 50), 2.0, ToolType.BROOM)
    end

    tasks[i] = task
  end

  -- Release all tasks back to appropriate pools
  for i, task in ipairs(tasks) do
    local taskType = i % 4
    local componentType

    if taskType == 0 then
      componentType = ComponentType.MOVEMENT_TASK
    elseif taskType == 1 then
      componentType = ComponentType.MINING_TASK
    elseif taskType == 2 then
      componentType = ComponentType.CONSTRUCTION_TASK
    else
      componentType = ComponentType.CLEANING_TASK
    end

    TaskComponentPool:release(task, componentType)
  end
end

-- Run comprehensive benchmarks
local function runBenchmarks()
  print("TaskComponentPool Performance Benchmark")
  print("======================================")
  print("Comparing object pooling vs traditional allocation")

  -- Initialize pool system (skip preallocation for now due to constructor issue)
  TaskComponentPool.config.initialPoolSize = 0 -- Skip preallocation
  TaskComponentPool:init(0)

  local results = {}
  local testSize = BENCHMARK_ITERATIONS.medium -- Use medium-sized test

  -- Individual component benchmarks
  print("\n" .. string.rep("=", 50))
  print("INDIVIDUAL COMPONENT BENCHMARKS")
  print(string.rep("=", 50))

  results.movementNonPooled = measurePerformance("MovementTask (Non-Pooled)", benchmarkNonPooledMovementTask, testSize)
  results.movementPooled = measurePerformance("MovementTask (Pooled)", benchmarkPooledMovementTask, testSize)

  results.miningNonPooled = measurePerformance("MiningTask (Non-Pooled)", benchmarkNonPooledMiningTask, testSize)
  results.miningPooled = measurePerformance("MiningTask (Pooled)", benchmarkPooledMiningTask, testSize)

  results.constructionNonPooled =
    measurePerformance("ConstructionTask (Non-Pooled)", benchmarkNonPooledConstructionTask, testSize)
  results.constructionPooled =
    measurePerformance("ConstructionTask (Pooled)", benchmarkPooledConstructionTask, testSize)

  results.cleaningNonPooled = measurePerformance("CleaningTask (Non-Pooled)", benchmarkNonPooledCleaningTask, testSize)
  results.cleaningPooled = measurePerformance("CleaningTask (Pooled)", benchmarkPooledCleaningTask, testSize)

  -- Mixed workload benchmarks
  print("\n" .. string.rep("=", 50))
  print("MIXED WORKLOAD BENCHMARKS")
  print(string.rep("=", 50))

  results.mixedNonPooled = measurePerformance("Mixed Workload (Non-Pooled)", benchmarkNonPooledMixedWorkload, testSize)
  results.mixedPooled = measurePerformance("Mixed Workload (Pooled)", benchmarkPooledMixedWorkload, testSize)

  -- Performance comparison summary
  print("\n" .. string.rep("=", 50))
  print("PERFORMANCE COMPARISON SUMMARY")
  print(string.rep("=", 50))

  local function printComparison(name, nonPooled, pooled)
    local speedup = nonPooled.timePerOperation / pooled.timePerOperation
    local memoryReduction = ((nonPooled.memoryUsed - pooled.memoryUsed) / nonPooled.memoryUsed) * 100

    print(string.format("\n%s:", name))
    print(string.format("  Speed improvement: %.1fx faster", speedup))
    print(string.format("  Memory reduction: %.1f%%", memoryReduction))
    print(string.format("  Non-pooled ops/sec: %.0f", nonPooled.operationsPerSecond))
    print(string.format("  Pooled ops/sec: %.0f", pooled.operationsPerSecond))
  end

  printComparison("MovementTask", results.movementNonPooled, results.movementPooled)
  printComparison("MiningTask", results.miningNonPooled, results.miningPooled)
  printComparison("ConstructionTask", results.constructionNonPooled, results.constructionPooled)
  printComparison("CleaningTask", results.cleaningNonPooled, results.cleaningPooled)
  printComparison("Mixed Workload", results.mixedNonPooled, results.mixedPooled)

  -- Pool statistics
  print("\n" .. string.rep("=", 50))
  print("POOL STATISTICS")
  print(string.rep("=", 50))

  local totalStats, poolStats = TaskComponentPool:getPoolStats()
  print(string.format("Total components acquired: %d", totalStats.totalAcquired))
  print(string.format("Total components released: %d", totalStats.totalReleased))
  print(string.format("Total components created: %d", totalStats.totalCreated))
  print(string.format("Total components reused: %d", totalStats.totalReused))
  print(string.format("Overall reuse rate: %.1f%%", (totalStats.totalReused / totalStats.totalAcquired) * 100))

  print("\nPer-component type statistics:")
  local componentNames = {
    [ComponentType.MOVEMENT_TASK] = "MovementTask",
    [ComponentType.MINING_TASK] = "MiningTask",
    [ComponentType.CONSTRUCTION_TASK] = "ConstructionTask",
    [ComponentType.CLEANING_TASK] = "CleaningTask",
  }

  for componentType, stats in pairs(poolStats) do
    local name = componentNames[componentType] or "Unknown"
    local reuseRate = stats.acquired > 0 and (stats.reused / stats.acquired) * 100 or 0
    print(
      string.format(
        "  %s: %d acquired, %d reused (%.1f%% reuse rate), pool size: %d",
        name,
        stats.acquired,
        stats.reused,
        reuseRate,
        totalStats.poolSizes[componentType]
      )
    )
  end

  print("\n" .. string.rep("=", 50))
  print("BENCHMARK COMPLETE")
  print(string.rep("=", 50))
end

-- Run the benchmarks
runBenchmarks()
