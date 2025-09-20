-- Test: Legacy System Migration
-- Verifies TaskQueue ECS integration and legacy Task.lua replacement

local luaunit = require("testing.luaunit")
local Vec2 = require("game.utils.Vec2")
local enums = require("game.utils.enums")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

-- Mock EntityManager for testing
local MockEntityManager = {
  entities = {},
  components = {}
}

function MockEntityManager:addComponent(entityId, componentType, component)
  if not self.components[entityId] then
    self.components[entityId] = {}
  end
  self.components[entityId][componentType] = component
end

function MockEntityManager:getComponent(entityId, componentType)
  if self.components[entityId] then
    return self.components[entityId][componentType]
  end
  return nil
end

-- Mock TaskComponentPool
local MockTaskComponentPool = {
  pools = {}
}

function MockTaskComponentPool:acquire(componentType)
  -- Return a mock movement task component
  if componentType == ComponentType.MOVEMENT_TASK then
    return {
      componentType = ComponentType.MOVEMENT_TASK,
      targetPosition = nil,
      isComplete = false,
      initialize = function(self, target, requiredDist, speed)
        self.targetPosition = target
        self.requiredDistance = requiredDist or 0.5
        self.movementSpeed = speed or 1.0
      end
    }
  end
  return nil
end

-- Mock Logger
local MockLogger = {
  info = function(msg) end,
  warn = function(msg) end,
  error = function(msg) end
}

-- Set up mocks
package.loaded["game.systems.EntityManager"] = MockEntityManager
package.loaded["game.systems.TaskComponentPool"] = MockTaskComponentPool
package.loaded["logger"] = MockLogger
_G.EntityManager = MockEntityManager
_G.Logger = MockLogger

-- Import TaskQueue after mocks
local TaskQueue = require("game.components.TaskQueue")

local TestLegacyMigration = {}

function TestLegacyMigration:setUp()
  -- Clean up mocks before each test
  MockEntityManager.entities = {}
  MockEntityManager.components = {}
  MockTaskComponentPool.pools = {}
end

function TestLegacyMigration:test_taskqueue_default_legacy_mode()
  local taskQueue = TaskQueue.new(1)
  
  luaunit.assertFalse(taskQueue:isECSMode())
  luaunit.assertEquals(taskQueue.maxConcurrentTasks, 1)
  luaunit.assertFalse(taskQueue:hasActiveTasks())
end

function TestLegacyMigration:test_taskqueue_ecs_mode_toggle()
  local taskQueue = TaskQueue.new(1)
  
  -- Enable ECS mode
  taskQueue:enableECSMode()
  luaunit.assertTrue(taskQueue:isECSMode())
  
  -- Disable ECS mode
  taskQueue:disableECSMode()
  luaunit.assertFalse(taskQueue:isECSMode())
end

function TestLegacyMigration:test_taskqueue_legacy_task_handling()
  local taskQueue = TaskQueue.new(1)
  
  -- Mock legacy task
  local legacyTask = {
    type = TaskType.MOVETO,
    target = Vec2.new(5, 5),
    isComplete = false,
    perform = function() end
  }
  
  taskQueue:push(legacyTask)
  luaunit.assertTrue(taskQueue:hasActiveTasks())
  luaunit.assertEquals(taskQueue:getActiveTaskCount(), 1)
  
  local poppedTask = taskQueue:pop()
  luaunit.assertEquals(poppedTask, legacyTask)
end

function TestLegacyMigration:test_taskqueue_ecs_movement_task()
  local entityId = 123
  local taskQueue = TaskQueue.new(entityId)
  
  -- Enable ECS mode
  taskQueue:enableECSMode()
  
  -- Add movement task
  local targetPos = Vec2.new(10, 10)
  local success = taskQueue:addMovementTask(targetPos)
  
  luaunit.assertTrue(success)
  luaunit.assertTrue(taskQueue:hasActiveTasks())
  luaunit.assertEquals(taskQueue:getActiveTaskCount(), 1)
  
  -- Verify the component was added to EntityManager
  local component = MockEntityManager:getComponent(entityId, ComponentType.MOVEMENT_TASK)
  luaunit.assertNotNil(component)
  luaunit.assertEquals(component.targetPosition, targetPos)
end

function TestLegacyMigration:test_taskqueue_ecs_task_limit()
  local taskQueue = TaskQueue.new(1)
  taskQueue:enableECSMode()
  
  -- Add first task (should succeed)
  local success1 = taskQueue:addMovementTask(Vec2.new(1, 1))
  luaunit.assertTrue(success1)
  
  -- Try to add second task (should fail due to maxConcurrentTasks = 1)
  local success2 = taskQueue:addMovementTask(Vec2.new(2, 2))
  luaunit.assertFalse(success2)
  
  luaunit.assertEquals(taskQueue:getActiveTaskCount(), 1)
end

function TestLegacyMigration:test_taskqueue_task_type_mapping()
  local taskQueue = TaskQueue.new(1)
  
  -- Test TaskType to ComponentType mapping
  local legacyTask = { type = TaskType.MOVETO }
  local componentType = taskQueue:getTaskComponentType(legacyTask)
  luaunit.assertEquals(componentType, ComponentType.MOVEMENT_TASK)
  
  legacyTask = { type = TaskType.MINE }
  componentType = taskQueue:getTaskComponentType(legacyTask)
  luaunit.assertEquals(componentType, ComponentType.MINING_TASK)
  
  legacyTask = { type = TaskType.CONSTRUCT }
  componentType = taskQueue:getTaskComponentType(legacyTask)
  luaunit.assertEquals(componentType, ComponentType.CONSTRUCTION_TASK)
  
  legacyTask = { type = TaskType.CLEAN }
  componentType = taskQueue:getTaskComponentType(legacyTask)
  luaunit.assertEquals(componentType, ComponentType.CLEANING_TASK)
end

function TestLegacyMigration:test_taskqueue_reset_behavior()
  local taskQueue = TaskQueue.new(1)
  
  -- Test legacy mode reset
  local legacyTask = { type = TaskType.MOVETO, isComplete = false }
  taskQueue:push(legacyTask)
  taskQueue.currentTask = legacyTask
  
  taskQueue:reset()
  luaunit.assertFalse(taskQueue:hasActiveTasks())
  luaunit.assertNil(taskQueue.currentTask)
  
  -- Test ECS mode reset
  taskQueue:enableECSMode()
  taskQueue.activeTaskComponents[ComponentType.MOVEMENT_TASK] = { isComplete = false }
  
  taskQueue:reset()
  luaunit.assertFalse(taskQueue:hasActiveTasks())
end

function TestLegacyMigration:test_taskqueue_ecs_mode_without_pool_fails()
  local taskQueue = TaskQueue.new(1)
  taskQueue:enableECSMode()
  
  -- Mock pool failure
  function MockTaskComponentPool:acquire()
    return nil
  end
  
  local success = taskQueue:addMovementTask(Vec2.new(1, 1))
  luaunit.assertFalse(success)
end

-- Run the tests
if not package.loaded["testing.runAll"] then
  luaunit.LuaUnit.run()
end

return TestLegacyMigration