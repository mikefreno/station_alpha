-- Performance benchmark suite for ECS task architecture
-- Tests various scenarios to measure performance improvements

-- Set up package path
package.path = package.path .. ";./?.lua;./?/init.lua;./game/?.lua"

require("testing.loveStub")

-- Import systems and components
local TaskComponentPool = require("game.systems.TaskComponentPool")
local TaskExecutionSystem = require("game.systems.TaskExecutionSystem")
local MovementSystem = require("game.systems.MovementSystem")
local SpatialIndex = require("game.systems.SpatialIndex")
local PerformanceMonitor = require("game.systems.PerformanceMonitor")
local EntityManager = require("game.systems.EntityManager")
local Position = require("game.systems.Position")

-- Legacy systems for comparison
local TaskManager = require("game.systems.TaskManager")

-- Utilities
local Vec2 = require("game.utils.Vec2")
local ComponentType = require("game.utils.enums").ComponentType

local TaskPerformanceBenchmark = {}

function TaskPerformanceBenchmark:setUp()
  -- Initialize systems
  self.entityManager = EntityManager.init()
  self.taskComponentPool = TaskComponentPool
  self.taskExecutionSystem = TaskExecutionSystem
  self.movementSystem = MovementSystem.new()
  self.spatialIndex = SpatialIndex
  self.performanceMonitor = PerformanceMonitor
  
  -- Initialize all systems
  if not self.taskExecutionSystem.isInitialized then
    self.taskExecutionSystem:init()
  end
  if not self.spatialIndex.isInitialized then
    self.spatialIndex:init()
  end
  if not self.performanceMonitor.isInitialized then
    self.performanceMonitor:init()
  end

  -- Legacy systems
  self.legacyTaskManager = TaskManager.new()

  -- Test entities storage
  self.testEntities = {}

  -- Performance results
  self.results = {}
end

function TaskPerformanceBenchmark:tearDown()
  self.testEntities = {}
  self.results = {}
end

-- Helper function to create test entities
function TaskPerformanceBenchmark:createTestEntities(count, area_size)
  area_size = area_size or 100

  for _ = 1, count do
    local entity = self.entityManager:createEntity()
    local x = math.random(1, area_size)
    local y = math.random(1, area_size)

    -- Add position component
    local position = Vec2.new(x, y)
    self.entityManager:addComponent(entity, ComponentType.POSITION, position)

    -- Register with spatial index
    self.spatialIndex:addEntity(entity, x, y)

    table.insert(self.testEntities, entity)
  end
end

-- Helper function to create test tasks
function TaskPerformanceBenchmark:createTestTasks(entity_count, tasks_per_entity)
  tasks_per_entity = tasks_per_entity or 1

  for i = 1, entity_count do
    local entity = self.testEntities[i]
    if not entity then break end

    for _ = 1, tasks_per_entity do
      -- Create movement task
      local taskComponent = self.taskComponentPool:acquire(ComponentType.MOVEMENT_TASK)
      if taskComponent then
        -- Set task properties (replace initialize call with direct property setting)
        taskComponent.targetPosition = Vec2.new(
          math.random(1, 100),
          math.random(1, 100)
        )
        taskComponent.isComplete = false
        
        -- Add to entity
        self.entityManager:addComponent(entity, ComponentType.MOVEMENT_TASK, taskComponent)
      end
    end
  end
end

-- Benchmark 1: Task Creation Performance
function TaskPerformanceBenchmark:testTaskCreationPerformance()
  print("=== Task Creation Performance Benchmark ===")
  
  local scenarios = {
    {name = "Small Scale", entities = 100, tasks_per_entity = 1},
    {name = "Medium Scale", entities = 500, tasks_per_entity = 2},
    {name = "Large Scale", entities = 1000, tasks_per_entity = 3}
  }
  
  for _, scenario in ipairs(scenarios) do
    print(string.format("\n--- %s: %d entities, %d tasks/entity ---", 
          scenario.name, scenario.entities, scenario.tasks_per_entity))
    
    -- Test ECS system
    self:setUp()
    self:createTestEntities(scenario.entities)
    
    local start_time = love.timer.getTime()
    self:createTestTasks(scenario.entities, scenario.tasks_per_entity)
    local ecs_time = love.timer.getTime() - start_time
    
    print(string.format("ECS Task Creation: %.4f seconds", ecs_time))
    
    -- Test legacy system (simplified comparison)
    start_time = love.timer.getTime()
    for i = 1, scenario.entities * scenario.tasks_per_entity do
      local task = {
        type = "movement",
        entity_id = i,
        priority = 1,
        parameters = {
          target_position = Vec2:new(math.random(1, 100), math.random(1, 100))
        }
      }
      -- Simulate legacy task creation overhead
      table.insert({}, task)
    end
    local legacy_time = love.timer.getTime() - start_time
    
    print(string.format("Legacy Task Creation: %.4f seconds", legacy_time))
    print(string.format("Performance Improvement: %.2fx", legacy_time / ecs_time))
    
    self:tearDown()
  end
end

-- Benchmark 2: Spatial Indexing Performance
function TaskPerformanceBenchmark:testSpatialIndexPerformance()
  print("\n=== Spatial Indexing Performance Benchmark ===")
  
  local scenarios = {
    {name = "Small Scale", entities = 100, queries = 1000},
    {name = "Medium Scale", entities = 500, queries = 5000},
    {name = "Large Scale", entities = 1000, queries = 10000}
  }
  
  for _, scenario in ipairs(scenarios) do
    print(string.format("\n--- %s: %d entities, %d queries ---", 
          scenario.name, scenario.entities, scenario.queries))
    
    self:setUp()
    self:createTestEntities(scenario.entities)
    
    -- Test spatial index queries
    local start_time = love.timer.getTime()
    for _ = 1, scenario.queries do
      local x = math.random(1, 100)
      local y = math.random(1, 100)
      self.spatialIndex:getNearbyEntities(x, y, 5)
    end
    local spatial_time = love.timer.getTime() - start_time
    
    print(string.format("Spatial Index Queries: %.4f seconds", spatial_time))
    
    -- Test linear search (legacy approach)
    start_time = love.timer.getTime()
    for _ = 1, scenario.queries do
      local query_x = math.random(1, 100)
      local query_y = math.random(1, 100)
      local nearby = {}

      -- Linear search through all entities
      for _, entity in ipairs(self.testEntities) do
        local pos_x, pos_y = Position:get(entity)
        if pos_x and pos_y then
          local distance = math.sqrt((pos_x - query_x)^2 + (pos_y - query_y)^2)
          if distance <= 5 then
            table.insert(nearby, entity)
          end
        end
      end
    end
    local linear_time = love.timer.getTime() - start_time
    
    print(string.format("Linear Search Queries: %.4f seconds", linear_time))
    print(string.format("Performance Improvement: %.2fx", linear_time / spatial_time))
    
    self:tearDown()
  end
end

-- Benchmark 3: Task Execution Performance
function TaskPerformanceBenchmark:testTaskExecutionPerformance()
  print("\n=== Task Execution Performance Benchmark ===")
  
  local scenarios = {
    {name = "Small Scale", entities = 100, iterations = 100},
    {name = "Medium Scale", entities = 500, iterations = 100},
    {name = "Large Scale", entities = 1000, iterations = 50}
  }
  
  for _, scenario in ipairs(scenarios) do
    print(string.format("\n--- %s: %d entities, %d iterations ---", 
          scenario.name, scenario.entities, scenario.iterations))
    
    self:setUp()
    self:createTestEntities(scenario.entities)
    self:createTestTasks(scenario.entities, 2) -- 2 tasks per entity
    
    -- Test ECS execution system
    self.performanceMonitor:startFrame()
    local start_time = love.timer.getTime()
    
    for i = 1, scenario.iterations do
      self.taskExecutionSystem:update(1/60) -- 60 FPS simulation
      self.movementSystem:update(1/60)
    end
    
    local ecs_time = love.timer.getTime() - start_time
    self.performanceMonitor:endFrame()
    
    print(string.format("ECS Task Execution: %.4f seconds", ecs_time))
    print(string.format("Average FPS: %.2f", scenario.iterations / ecs_time))
    
    -- Get performance statistics
    local stats = self.performanceMonitor:getStatistics()
    if stats.frame_time.average > 0 then
      print(string.format("Average Frame Time: %.4f ms", stats.frame_time.average * 1000))
      print(string.format("Peak Frame Time: %.4f ms", stats.frame_time.peak * 1000))
    end
    
    self:tearDown()
  end
end

-- Benchmark 4: Memory Usage Analysis
function TaskPerformanceBenchmark:testMemoryUsage()
  print("\n=== Memory Usage Benchmark ===")
  
  local scenarios = {
    {name = "Component Pool", entities = 1000, tasks_per_entity = 5},
    {name = "Spatial Index", entities = 2000, tasks_per_entity = 1},
    {name = "Full System", entities = 1500, tasks_per_entity = 3}
  }
  
  for _, scenario in ipairs(scenarios) do
    print(string.format("\n--- %s: %d entities, %d tasks/entity ---", 
          scenario.name, scenario.entities, scenario.tasks_per_entity))
    
    -- Force garbage collection before measurement
    collectgarbage("collect")
    local start_memory = collectgarbage("count")
    
    self:setUp()
    self:createTestEntities(scenario.entities)
    self:createTestTasks(scenario.entities, scenario.tasks_per_entity)
    
    -- Run some processing to simulate real usage
    for _ = 1, 10 do
      self.taskExecutionSystem:update(1/60)
      self.movementSystem:update(1/60)
    end
    
    collectgarbage("collect")
    local end_memory = collectgarbage("count")
    local memory_used = end_memory - start_memory
    
    print(string.format("Memory Used: %.2f KB", memory_used))
    print(string.format("Memory per Entity: %.2f bytes", (memory_used * 1024) / scenario.entities))
    print(string.format("Memory per Task: %.2f bytes", 
          (memory_used * 1024) / (scenario.entities * scenario.tasks_per_entity)))
    
    self:tearDown()
  end
end

-- Benchmark 5: Throughput Analysis
function TaskPerformanceBenchmark:testThroughputAnalysis()
  print("\n=== Throughput Analysis Benchmark ===")
  
  self:setUp()
  self:createTestEntities(1000)
  
  local total_tasks_processed = 0
  local test_duration = 5 -- 5 seconds
  local start_time = love.timer.getTime()

  print("Running throughput test for 5 seconds...")

  while (love.timer.getTime() - start_time) < test_duration do
    -- Add new tasks continuously
    for _ = 1, 10 do
      local entity = self.testEntities[math.random(1, #self.testEntities)]
      local taskComponent = self.taskComponentPool:acquire()
      taskComponent:initialize(
        "movement",
        entity,
        math.random(1, 5),
        {
          target_position = Vec2:new(math.random(1, 100), math.random(1, 100))
        }
      )
      self.taskExecutionSystem:addTask(taskComponent)
    end

    -- Process tasks
    self.taskExecutionSystem:update(1/60)
    self.movementSystem:update(1/60)

    total_tasks_processed = total_tasks_processed + 10
  end
  
  local actual_duration = love.timer.getTime() - start_time
  local throughput = total_tasks_processed / actual_duration
  
  print(string.format("Total tasks processed: %d", total_tasks_processed))
  print(string.format("Actual test duration: %.2f seconds", actual_duration))
  print(string.format("Throughput: %.2f tasks/second", throughput))
  
  self:tearDown()
end

-- Main benchmark runner
function TaskPerformanceBenchmark:runAllBenchmarks()
  print("Starting Performance Benchmark Suite...")
  print(string.rep("=", 50))

  self:testTaskCreationPerformance()
  self:testSpatialIndexPerformance()
  self:testTaskExecutionPerformance()
  self:testMemoryUsage()
  self:testThroughputAnalysis()

  print("\n" .. string.rep("=", 50))
  print("Performance Benchmark Suite Complete!")
end

-- Export for external use
return TaskPerformanceBenchmark