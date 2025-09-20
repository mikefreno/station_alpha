package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

-- Load test framework and stubs
local luaunit = require("testing.luaunit")

-- Load Love2D stub
require("testing.loveStub")

-- Mock Logger
local Logger = {
  info = function(self, msg) end,
  warn = function(self, msg) end,
  error = function(self, msg) end,
  debug = function(self, msg) end,
}
package.loaded["logger"] = Logger

-- Mock Vec2
local Vec2 = {
  new = function(x, y)
    return { x = x or 0, y = y or 0 }
  end,
}
package.loaded["utils.Vec2"] = Vec2

-- Mock enums
local enums = {
  ComponentType = {
    POSITION = 1,
    MOVEMENT_TASK = 2,
    MINING_TASK = 3,
    CONSTRUCTION_TASK = 4,
    CLEANING_TASK = 5,
  },
}
package.loaded["utils.enums"] = enums

-- Mock EntityManager for testing
local MockEntityManager = {
  entities = {},
  components = {},
}

function MockEntityManager:reset()
  self.entities = {}
  self.components = {}
end

function MockEntityManager:query(componentType)
  local result = {}
  if self.components[componentType] then
    for entityId, _ in pairs(self.components[componentType]) do
      table.insert(result, entityId)
    end
  end
  return result
end

function MockEntityManager:getComponent(entityId, componentType)
  if self.components[componentType] and self.components[componentType][entityId] then
    return self.components[componentType][entityId]
  end
  return nil
end

function MockEntityManager:addComponent(entityId, componentType, component)
  if not self.components[componentType] then
    self.components[componentType] = {}
  end
  self.components[componentType][entityId] = component
end

function MockEntityManager:removeComponent(entityId, componentType)
  if self.components[componentType] then
    self.components[componentType][entityId] = nil
  end
end

package.loaded["systems.EntityManager"] = MockEntityManager

-- Mock task components
local MockMiningTask = {
  requiredDistance = 2.0,
  estimatedDuration = 5.0,
}

function MockMiningTask:isInRange(position)
  local target = self:getTargetPosition()
  if not target or not position then
    return false
  end

  local dx = position.x - target.x
  local dy = position.y - target.y
  local distance = math.sqrt(dx * dx + dy * dy)
  return distance <= self.requiredDistance
end

function MockMiningTask:getTargetPosition()
  return self.targetPosition or Vec2.new(10, 10)
end

function MockMiningTask.new(targetPos, requiredDist)
  local task = {}
  for k, v in pairs(MockMiningTask) do
    task[k] = v
  end
  task.targetPosition = targetPos or Vec2.new(10, 10)
  task.requiredDistance = requiredDist or 2.0
  return task
end

package.loaded["components.MiningTask"] = MockMiningTask

-- Mock MovementTask
local MockMovementTask = {
  targetPosition = nil,
  requiredDistance = 1.0,
  estimatedDuration = 3.0,
  path = {},
}

function MockMovementTask:setPath(path)
  self.path = path or {}
end

function MockMovementTask.newFromPool(targetPos, requiredDist, speed)
  local task = {}
  for k, v in pairs(MockMovementTask) do
    task[k] = v
  end
  task.targetPosition = targetPos
  task.requiredDistance = requiredDist or 1.0
  task.speed = speed or 1.0
  return task
end

package.loaded["components.MovementTask"] = MockMovementTask

-- Load the systems
local TaskDependencyResolver = require("game.systems.TaskDependencyResolver")
local TaskExecutionSystem = require("game.systems.TaskExecutionSystem")

-- Test Suite
TestTaskExecutionSystemIntegration = {}

function TestTaskExecutionSystemIntegration:setUp()
  -- Reset all state before each test
  MockEntityManager:reset()
  TaskDependencyResolver.isInitialized = false
  TaskExecutionSystem.isInitialized = false
  TaskExecutionSystem.dependencyResolver = nil

  TaskDependencyResolver:init()
  TaskExecutionSystem:init()
end

function TestTaskExecutionSystemIntegration:tearDown()
  -- Clean up after each test
end

-- Test: TaskExecutionSystem can integrate with TaskDependencyResolver
function TestTaskExecutionSystemIntegration:test_integration_setup()
  -- Initialize both systems
  luaunit.assertTrue(TaskDependencyResolver:isReady())
  luaunit.assertTrue(TaskExecutionSystem.isInitialized)

  -- Set dependency resolver
  local success = TaskExecutionSystem:setDependencyResolver(TaskDependencyResolver)
  luaunit.assertTrue(success)
  luaunit.assertEquals(TaskExecutionSystem.dependencyResolver, TaskDependencyResolver)
end

-- Test: Complete processing pipeline with dependency resolution
function TestTaskExecutionSystemIntegration:test_complete_processing_pipeline()
  -- Set up the integration
  TaskExecutionSystem:setDependencyResolver(TaskDependencyResolver)

  -- Create test entity with mining task but wrong position
  local entityId = 1
  local entityPosition = Vec2.new(0, 0) -- Far from target
  local miningTask = MockMiningTask.new(Vec2.new(10, 10), 2.0) -- Target at (10,10)

  -- Add components to entity
  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, entityPosition)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, miningTask)

  -- Verify entity needs movement
  luaunit.assertTrue(TaskDependencyResolver:entityRequiresMovement(entityId))

  -- Run dependency resolution
  TaskDependencyResolver:resolveDependencies()

  -- Verify movement task was injected
  local movementTask = MockEntityManager:getComponent(entityId, enums.ComponentType.MOVEMENT_TASK)
  luaunit.assertNotNil(movementTask)

  -- Verify movement task targets the correct position
  luaunit.assertEquals(movementTask.targetPosition.x, 10)
  luaunit.assertEquals(movementTask.targetPosition.y, 10)

  -- Check statistics
  local stats = TaskDependencyResolver:getStatistics()
  luaunit.assertEquals(stats.entitiesAnalyzed, 1)
  luaunit.assertEquals(stats.dependenciesResolved, 1)
  luaunit.assertEquals(stats.movementTasksInjected, 1)
end

-- Test: Processing with no dependencies needed
function TestTaskExecutionSystemIntegration:test_no_dependencies_needed()
  TaskExecutionSystem:setDependencyResolver(TaskDependencyResolver)

  -- Create entity already in correct position
  local entityId = 1
  local entityPosition = Vec2.new(10, 10) -- Same as target
  local miningTask = MockMiningTask.new(Vec2.new(10, 10), 2.0)

  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, entityPosition)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, miningTask)

  -- Verify entity doesn't need movement
  luaunit.assertFalse(TaskDependencyResolver:entityRequiresMovement(entityId))

  -- Run dependency resolution
  TaskDependencyResolver:resolveDependencies()

  -- Verify no movement task was created
  local movementTask = MockEntityManager:getComponent(entityId, enums.ComponentType.MOVEMENT_TASK)
  luaunit.assertNil(movementTask)

  -- Check statistics
  local stats = TaskDependencyResolver:getStatistics()
  luaunit.assertEquals(stats.entitiesAnalyzed, 1)
  luaunit.assertEquals(stats.dependenciesResolved, 1)
  luaunit.assertEquals(stats.movementTasksInjected, 0)
end

-- Test: Error handling when dependency resolver not set
function TestTaskExecutionSystemIntegration:test_missing_dependency_resolver()
  -- Don't set dependency resolver
  luaunit.assertNil(TaskExecutionSystem.dependencyResolver)

  -- Create entity with task
  local entityId = 1
  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, Vec2.new(0, 0))
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, MockMiningTask.new())

  -- This should not crash even without dependency resolver
  -- (The system will just skip dependency resolution)
  -- We can't test the full pipeline here since we don't have processors set up
end

-- Test: Performance with multiple entities
function TestTaskExecutionSystemIntegration:test_performance_multiple_entities()
  TaskExecutionSystem:setDependencyResolver(TaskDependencyResolver)

  -- Create 10 entities that need movement
  for i = 1, 10 do
    local entityPosition = Vec2.new(0, 0)
    local miningTask = MockMiningTask.new(Vec2.new(i * 5, i * 5), 2.0)

    MockEntityManager:addComponent(i, enums.ComponentType.POSITION, entityPosition)
    MockEntityManager:addComponent(i, enums.ComponentType.MINING_TASK, miningTask)
  end

  -- Run dependency resolution
  local startTime = love.timer.getTime()
  TaskDependencyResolver:resolveDependencies()
  local endTime = love.timer.getTime()

  -- Verify all entities got movement tasks
  for i = 1, 10 do
    local movementTask = MockEntityManager:getComponent(i, enums.ComponentType.MOVEMENT_TASK)
    luaunit.assertNotNil(movementTask)
  end

  -- Check performance stats
  local stats = TaskDependencyResolver:getStatistics()
  luaunit.assertEquals(stats.entitiesAnalyzed, 10)
  luaunit.assertEquals(stats.dependenciesResolved, 10)
  luaunit.assertEquals(stats.movementTasksInjected, 10)

  -- Verify performance (should complete quickly)
  local totalTime = endTime - startTime
  luaunit.assertTrue(totalTime < 0.1) -- Should complete in less than 100ms
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
