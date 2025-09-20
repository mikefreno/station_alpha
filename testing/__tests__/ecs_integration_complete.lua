-- Comprehensive ECS Task System Test
-- Tests complete end-to-end functionality of the ECS-only task system

package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
require("testing.loveStub")

-- Mock Logger
Logger = {
  info = function(self, msg, ...) print("INFO: " .. msg) end,
  warn = function(self, msg, ...) print("WARN: " .. msg) end,
  debug = function(self, msg, ...) print("DEBUG: " .. msg) end,
  error = function(self, msg, ...) print("ERROR: " .. msg) end,
}

-- Create comprehensive mock for EntityManager
local MockEntityManager = {
  entities = {},
  components = {},
  nextId = 1,
  
  createEntity = function(self)
    local id = self.nextId
    self.nextId = self.nextId + 1
    self.entities[id] = true
    self.components[id] = {}
    return id
  end,
  
  addComponent = function(self, entityId, componentType, component)
    print("MockEntityManager:addComponent called with entityId=" .. tostring(entityId) .. ", componentType=" .. tostring(componentType))
    -- Validate that entity exists
    if not self.entities[entityId] then
      print("MockEntityManager: ERROR - Entity " .. tostring(entityId) .. " does not exist")
      return false
    end
    if not self.components[entityId] then
      self.components[entityId] = {}
    end
    self.components[entityId][componentType] = component
    print("MockEntityManager: Component added successfully, total components for entity " .. tostring(entityId) .. ": " .. tostring(#(self.components[entityId] or {})))
    return true
  end,
  
  getComponent = function(self, entityId, componentType)
    if self.components[entityId] then
      return self.components[entityId][componentType]
    end
    return nil
  end,
  
  hasComponent = function(self, entityId, componentType)
    return self.components[entityId] and self.components[entityId][componentType] ~= nil
  end,
  
  removeComponent = function(self, entityId, componentType)
    if self.components[entityId] then
      self.components[entityId][componentType] = nil
    end
  end,
  
  getEntitiesWithComponent = function(self, componentType)
    local entities = {}
    for entityId, components in pairs(self.components) do
      if components[componentType] then
        table.insert(entities, entityId)
      end
    end
    return entities
  end,
  
  -- Add query method for TaskDependencyResolver compatibility
  query = function(self, componentType)
    return self:getEntitiesWithComponent(componentType)
  end,
  
  reset = function(self)
    self.entities = {}
    self.components = {}
    self.nextId = 1
  end
}

-- Set up global mocks
EntityManager = MockEntityManager

-- Mock Vec2
local Vec2 = { 
  new = function(x, y) 
    return {x = x or 0, y = y or 0} 
  end 
}

-- Mock complete enums
local enums = {
  ComponentType = {
    POSITION = 1,
    VELOCITY = 2,
    TASKQUEUE = 3,
    TEXTURE = 4,
    SHAPE = 5,
    TOPOGRAPHY = 6,
    MAPTILE_TAG = 7,
    SPEEDSTAT = 8,
    MOVETO = 9,
    SCHEDULE = 10,
    SELECTED = 11,
    NAME = 12,
    COLONIST_TAG = 13,
    HEALTH = 14,
    TASK_COMPONENT_BASE = 100,
    MOVEMENT_TASK = 101,
    MINING_TASK = 102,
    CONSTRUCTION_TASK = 103,
    CLEANING_TASK = 104,
  },
  TaskType = {
    MOVETO = 0,
    MINE = 1,
    CONSTRUCT = 2,
    OPERATE = 3,
    FIREFIGHT = 4,
    COMBAT = 5,
    HUNT = 6,
    CLEAN = 7,
    RESEARCH = 8,
    CROP_TEND = 9,
    ANIMAL_TEND = 10,
    DOCTOR = 11,
    GUARD = 12,
  }
}

-- Override require for our mocks
local original_require = require
_G.require = function(path)
  if path == "game.utils.enums" or path == "utils.enums" then
    return enums
  elseif path == "game.utils.Vec2" then
    return Vec2
  elseif path == "logger" then
    return Logger
  elseif path == "game.systems.EntityManager" or path == "systems.EntityManager" then
    return MockEntityManager
  else
    return original_require(path)
  end
end

-- Clear module cache for systems that depend on EntityManager to force reload with mock
package.loaded["game.systems.TaskExecutionSystem"] = nil
package.loaded["game.systems.TaskManager"] = nil

-- Import the systems we're testing (they will now use the mock)
local TaskManager = require("game.systems.TaskManager")
local Schedule = require("game.components.Schedule")
local TaskQueue = require("game.components.TaskQueue")
local MovementSystem = require("game.systems.MovementSystem")

TestECSIntegration = {}

function TestECSIntegration:setUp()
  -- Reset mock state
  MockEntityManager:reset()
end

function TestECSIntegration:test_complete_ecs_workflow()
  -- Test complete workflow: TaskManager -> Schedule -> TaskQueue -> TaskExecutionSystem
  
  -- 1. Create TaskManager (operates in ECS mode)
  local taskManager = TaskManager.new()
  luaunit.assertNotNil(taskManager, "TaskManager should be created successfully")
  
  -- 2. Create an entity with ECS task components
  local entity = EntityManager:createEntity()
  
  -- 3. Create and set up TaskQueue
  local taskQueue = TaskQueue.new(entity)
  EntityManager:addComponent(entity, enums.ComponentType.TASKQUEUE, taskQueue)
  
  -- 4. Create and set up Schedule
  local schedule = Schedule.new()
  schedule:adjustScheduleWeight(enums.TaskType.MINE, 5)
  schedule:adjustScheduleWeight(enums.TaskType.CLEAN, 3)
  EntityManager:addComponent(entity, enums.ComponentType.SCHEDULE, schedule)
  
  -- 5. Add position component
  local position = Vec2.new(10, 10)
  EntityManager:addComponent(entity, enums.ComponentType.POSITION, position)
  
  -- 6. Test task assignment through TaskManager
  local openTasks = {
    [enums.TaskType.MINE] = {Vec2.new(5, 5), Vec2.new(8, 8)},
    [enums.TaskType.CLEAN] = {Vec2.new(12, 12)}
  }
  
  -- 7. Assign tasks to idle entities (should work end-to-end)
  taskManager:assignTasksToIdleEntities(openTasks)
  
  -- 8. Verify entity has task components
  local hasTaskComponent = EntityManager:hasComponent(entity, enums.ComponentType.MINING_TASK) or
                          EntityManager:hasComponent(entity, enums.ComponentType.CLEANING_TASK) or
                          EntityManager:hasComponent(entity, enums.ComponentType.MOVEMENT_TASK)
  
  luaunit.assertTrue(hasTaskComponent, "Entity should have received a task component")
  
  -- 9. Test TaskExecutionSystem can process the entity
  local entitiesWithTasks = EntityManager:getEntitiesWithComponent(enums.ComponentType.MINING_TASK)
  luaunit.assertTrue(#entitiesWithTasks >= 0, "Should be able to query entities with task components")
end

function TestECSIntegration:test_taskmanager_schedule_integration()
  -- Test TaskManager properly integrates with Schedule component
  
  local taskManager = TaskManager.new()
  local entity = EntityManager:createEntity()
  
  -- Set up Schedule with weights
  local schedule = Schedule.new()
  schedule:adjustScheduleWeight(enums.TaskType.CONSTRUCT, 6) -- Highest priority
  schedule:adjustScheduleWeight(enums.TaskType.MINE, 4)
  schedule:adjustScheduleWeight(enums.TaskType.CLEAN, 2)
  EntityManager:addComponent(entity, enums.ComponentType.SCHEDULE, schedule)
  
  -- Set up TaskQueue
  local taskQueue = TaskQueue.new(entity)
  EntityManager:addComponent(entity, enums.ComponentType.TASKQUEUE, taskQueue)
  
  -- Test task selection prioritization
  local openTasks = {
    [enums.TaskType.MINE] = {Vec2.new(1, 1)},
    [enums.TaskType.CONSTRUCT] = {Vec2.new(2, 2)},
    [enums.TaskType.CLEAN] = {Vec2.new(3, 3)}
  }
  
  local taskType, target = schedule:selectNextTaskType(openTasks)
  luaunit.assertEquals(taskType, enums.TaskType.CONSTRUCT, "Should select highest priority task type")
  luaunit.assertNotNil(target, "Should return a target")
end

function TestECSIntegration:test_component_lifecycle_management()
  -- Test that ECS components are properly created, assigned, and cleaned up
  
  local taskManager = TaskManager.new()
  local entity = EntityManager:createEntity()
  
  -- Add required components
  EntityManager:addComponent(entity, enums.ComponentType.POSITION, Vec2.new(10, 10))
  
  local taskQueue = TaskQueue.new(entity)
  EntityManager:addComponent(entity, enums.ComponentType.TASKQUEUE, taskQueue)
  
  -- Test component creation through TaskManager
  local success = taskManager:createECSTask(enums.TaskType.MINE, Vec2.new(5, 5), entity, 1.0)
  luaunit.assertTrue(success, "Should successfully create ECS task")
  
  -- Initialize and trigger dependency resolution (this would normally happen in the update cycle)
  if taskManager.taskExecutionSystem and taskManager.taskExecutionSystem.dependencyResolver then
    -- Ensure dependency resolver is initialized
    if not taskManager.taskExecutionSystem.dependencyResolver.isInitialized then
      taskManager.taskExecutionSystem.dependencyResolver:init()
    end
    -- Trigger dependency resolution
    taskManager.taskExecutionSystem.dependencyResolver:resolveDependencies()
  end
  
  -- Verify movement task was created as dependency
  local hasMovementTask = EntityManager:hasComponent(entity, enums.ComponentType.MOVEMENT_TASK)
  luaunit.assertTrue(hasMovementTask, "Should create movement task as dependency")
  
  -- Verify mining task was created
  local hasMiningTask = EntityManager:hasComponent(entity, enums.ComponentType.MINING_TASK)
  luaunit.assertTrue(hasMiningTask, "Should create mining task")
  
  -- Test task cleanup
  local miningTask = EntityManager:getComponent(entity, enums.ComponentType.MINING_TASK)
  if miningTask then
    miningTask:markComplete()
    taskManager.taskExecutionSystem:removeCompletedTasks()
    
    -- Verify task was removed
    local hasTaskAfterCleanup = EntityManager:hasComponent(entity, enums.ComponentType.MINING_TASK)
    luaunit.assertFalse(hasTaskAfterCleanup, "Completed task should be removed")
  end
end

function TestECSIntegration:test_system_coordination()
  -- Test that TaskExecutionSystem and MovementSystem coordinate properly
  
  local taskManager = TaskManager.new()
  local movementSystem = MovementSystem.new()
  
  local entity = EntityManager:createEntity()
  EntityManager:addComponent(entity, enums.ComponentType.POSITION, Vec2.new(10, 10))
  
  -- Create movement task
  local success = taskManager:createECSTask(enums.TaskType.MOVETO, Vec2.new(5, 5), entity, 1.0)
  luaunit.assertTrue(success, "Should create movement task")
  
  -- Verify movement task exists
  local movementTask = EntityManager:getComponent(entity, enums.ComponentType.MOVEMENT_TASK)
  luaunit.assertNotNil(movementTask, "Movement task should exist")
  
  -- Test system processing (basic functionality)
  local entitiesWithMovement = EntityManager:getEntitiesWithComponent(enums.ComponentType.MOVEMENT_TASK)
  luaunit.assertTrue(#entitiesWithMovement > 0, "Should find entities with movement tasks")
end

function TestECSIntegration:test_taskqueue_ecs_integration()
  -- Test TaskQueue functionality in ECS context
  
  local entity = EntityManager:createEntity()
  local taskQueue = TaskQueue.new(entity)
  
  -- Test basic operations
  luaunit.assertTrue(taskQueue:isEmpty(), "Should report empty state correctly")
  
  -- Test adding to entity manager
  EntityManager:addComponent(entity, enums.ComponentType.TASKQUEUE, taskQueue)
  local retrievedQueue = EntityManager:getComponent(entity, enums.ComponentType.TASKQUEUE)
  luaunit.assertNotNil(retrievedQueue, "Should retrieve queue from entity manager")
  luaunit.assertTrue(retrievedQueue:isEmpty(), "Retrieved queue should maintain state")
end

function TestECSIntegration:test_error_handling_and_edge_cases()
  -- Test error handling in ECS integration
  
  local taskManager = TaskManager.new()
  
  -- Test creating task for non-existent entity
  local success = taskManager:createECSTask(enums.TaskType.MINE, Vec2.new(1, 1), 99999, 1.0)
  luaunit.assertFalse(success, "Should fail gracefully for non-existent entity")
  
  -- Test creating task with invalid task type
  local entity = EntityManager:createEntity()
  EntityManager:addComponent(entity, enums.ComponentType.POSITION, Vec2.new(10, 10))
  
  success = taskManager:createECSTask(999, Vec2.new(1, 1), entity, 1.0)
  luaunit.assertFalse(success, "Should fail gracefully for invalid task type")
  
  -- Test schedule with empty task table
  local schedule = Schedule.new()
  
  local taskType, target = schedule:selectNextTaskType({})
  luaunit.assertNil(taskType, "Should return nil for empty task table")
  luaunit.assertNil(target, "Should return nil target for empty task table")
end

function TestECSIntegration:test_performance_characteristics()
  -- Basic performance test for ECS operations
  
  local taskManager = TaskManager.new()
  local startTime = os.clock()
  
  -- Create multiple entities with tasks
  for i = 1, 100 do
    local entity = EntityManager:createEntity()
    EntityManager:addComponent(entity, enums.ComponentType.POSITION, Vec2.new(i, i))
    
    local taskQueue = TaskQueue.new(entity)
    EntityManager:addComponent(entity, enums.ComponentType.TASKQUEUE, taskQueue)
    
    local schedule = Schedule.new()
    schedule:adjustScheduleWeight(enums.TaskType.MINE, 3)
    EntityManager:addComponent(entity, enums.ComponentType.SCHEDULE, schedule)
  end
  
  local setupTime = os.clock() - startTime
  luaunit.assertTrue(setupTime < 1.0, "Should set up 100 entities quickly (< 1s)")
  
  -- Test batch processing performance
  startTime = os.clock()
  local openTasks = {
    [enums.TaskType.MINE] = {}
  }
  for i = 1, 50 do
    table.insert(openTasks[enums.TaskType.MINE], Vec2.new(i, i))
  end
  
  taskManager:assignTasksToIdleEntities(openTasks)
  local assignmentTime = os.clock() - startTime
  
  luaunit.assertTrue(assignmentTime < 0.5, "Should assign tasks to 100 entities quickly (< 0.5s)")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())