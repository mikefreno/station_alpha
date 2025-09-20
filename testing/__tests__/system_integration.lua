package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

require("testing.loveStub")
local lu = require("testing.luaunit")

-- System integration tests for the ECS task architecture
-- Tests complete task lifecycle with all systems working together

-- Mock the main systems for integration testing
local MockEntityManager = {
  entities = {},
  components = {},
  nextEntityId = 1,
}

function MockEntityManager:createEntity()
  local id = self.nextEntityId
  self.nextEntityId = self.nextEntityId + 1
  self.entities[id] = true
  self.components[id] = {}
  return id
end

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

function MockEntityManager:hasComponent(entityId, componentType)
  return self:getComponent(entityId, componentType) ~= nil
end

function MockEntityManager:getAllComponentsOfType(componentType)
  local result = {}
  for entityId, components in pairs(self.components) do
    if components[componentType] then
      result[entityId] = components[componentType]
    end
  end
  return result
end

-- Mock Logger
local MockLogger = {
  info = function(self, msg) end,
  warn = function(self, msg) end,
  error = function(self, msg) end,
}

-- Mock Vec2
local MockVec2 = {}
function MockVec2.new(x, y)
  return { x = x or 0, y = y or 0 }
end

-- Mock TaskQueue with ECS mode support
local MockTaskQueue = {}
MockTaskQueue.__index = MockTaskQueue

function MockTaskQueue.new(entityId)
  local self = setmetatable({}, MockTaskQueue)
  self.entityId = entityId
  self.tasks = {}
  self.activeTaskComponents = {}
  self.maxConcurrentTasks = 3
  self.ecsMode = false
  return self
end

function MockTaskQueue:enableECSMode()
  self.ecsMode = true
end

function MockTaskQueue:disableECSMode()
  self.ecsMode = false
end

function MockTaskQueue:isECSMode()
  return self.ecsMode
end

function MockTaskQueue:addMovementTask(targetPosition)
  if #self.activeTaskComponents >= self.maxConcurrentTasks then
    return false
  end
  
  local taskComponent = {
    componentType = "MOVEMENT_TASK",
    targetPosition = targetPosition,
    created = true
  }
  table.insert(self.activeTaskComponents, taskComponent)
  return true
end

function MockTaskQueue:push(task)
  table.insert(self.tasks, task)
end

function MockTaskQueue:reset()
  self.tasks = {}
  self.activeTaskComponents = {}
end

-- Mock components and enums
local MockComponentType = {
  POSITION = "POSITION",
  VELOCITY = "VELOCITY", 
  TASKQUEUE = "TASKQUEUE",
  MOVEMENT_TASK = "MOVEMENT_TASK",
  MINING_TASK = "MINING_TASK",
  SPEEDSTAT = "SPEEDSTAT",
  SELECTED = "SELECTED",
}

local MockTaskType = {
  MOVETO = "MOVETO",
  MINE = "MINE",
}

-- Mock Task (legacy)
local MockTask = {}
function MockTask.new(taskType, target)
  return {
    type = taskType,
    target = target,
    isLegacy = true
  }
end

-- Mock MovementSystem
local MockMovementSystem = {}
MockMovementSystem.__index = MockMovementSystem

function MockMovementSystem.new()
  local self = setmetatable({}, MockMovementSystem)
  self.processedEntities = 0
  self.completedMovements = 0
  return self
end

function MockMovementSystem:update(dt)
  self.processedEntities = 0
  self.completedMovements = 0
  
  local movementTasks = MockEntityManager:getAllComponentsOfType(MockComponentType.MOVEMENT_TASK)
  for entityId, movementTask in pairs(movementTasks) do
    self.processedEntities = self.processedEntities + 1
    
    local position = MockEntityManager:getComponent(entityId, MockComponentType.POSITION)
    if position then
      -- Simulate movement completion
      position.x = movementTask.targetPosition.x
      position.y = movementTask.targetPosition.y
      self.completedMovements = self.completedMovements + 1
    end
  end
end

-- Test Suite
TestSystemIntegration = {}

function TestSystemIntegration:setUp()
  -- Reset mock systems
  MockEntityManager.entities = {}
  MockEntityManager.components = {}
  MockEntityManager.nextEntityId = 1
end

function TestSystemIntegration:testCompleteTaskLifecycle()
  -- Test complete task lifecycle: assignment -> dependency resolution -> execution -> completion
  
  -- 1. Create entity with required components
  local entityId = MockEntityManager:createEntity()
  MockEntityManager:addComponent(entityId, MockComponentType.POSITION, MockVec2.new(0, 0))
  MockEntityManager:addComponent(entityId, MockComponentType.VELOCITY, MockVec2.new(0, 0))
  MockEntityManager:addComponent(entityId, MockComponentType.SPEEDSTAT, 1.0)
  
  local taskQueue = MockTaskQueue.new(entityId)
  taskQueue:enableECSMode()
  MockEntityManager:addComponent(entityId, MockComponentType.TASKQUEUE, taskQueue)
  
  -- 2. Assign a movement task through TaskQueue
  local targetPos = MockVec2.new(5, 5)
  local success = taskQueue:addMovementTask(targetPos)
  lu.assertTrue(success, "Should successfully add movement task")
  lu.assertEquals(#taskQueue.activeTaskComponents, 1, "Should have one active task component")
  
  -- 3. Verify task component was created
  local taskComponent = taskQueue.activeTaskComponents[1]
  lu.assertEquals(taskComponent.componentType, "MOVEMENT_TASK")
  lu.assertEquals(taskComponent.targetPosition, targetPos)
  
  -- 4. Simulate adding the task component to EntityManager (normally done by TaskComponentPool)
  MockEntityManager:addComponent(entityId, MockComponentType.MOVEMENT_TASK, {
    targetPosition = targetPos,
    requiredDistance = 0.5,
    movementSpeed = 1.0
  })
  
  -- 5. Process movement via MovementSystem
  local movementSystem = MockMovementSystem.new()
  movementSystem:update(0.016) -- 60 FPS
  
  -- 6. Verify movement was processed
  lu.assertEquals(movementSystem.processedEntities, 1, "Should process one entity")
  lu.assertEquals(movementSystem.completedMovements, 1, "Should complete one movement")
  
  -- 7. Verify position was updated
  local finalPosition = MockEntityManager:getComponent(entityId, MockComponentType.POSITION)
  lu.assertEquals(finalPosition.x, 5)
  lu.assertEquals(finalPosition.y, 5)
end

function TestSystemIntegration:testECSAndLegacyModeCompatibility()
  -- Test that ECS and legacy modes can coexist and switch seamlessly
  
  local entityId = MockEntityManager:createEntity()
  local taskQueue = MockTaskQueue.new(entityId)
  
  -- Start in legacy mode
  lu.assertFalse(taskQueue:isECSMode(), "Should start in legacy mode")
  
  -- Add legacy task
  taskQueue:push(MockTask.new(MockTaskType.MOVETO, MockVec2.new(1, 1)))
  lu.assertEquals(#taskQueue.tasks, 1, "Should have one legacy task")
  
  -- Switch to ECS mode
  taskQueue:enableECSMode()
  lu.assertTrue(taskQueue:isECSMode(), "Should be in ECS mode")
  
  -- Add ECS task
  local success = taskQueue:addMovementTask(MockVec2.new(2, 2))
  lu.assertTrue(success, "Should successfully add ECS task")
  lu.assertEquals(#taskQueue.activeTaskComponents, 1, "Should have one ECS task component")
  
  -- Both legacy and ECS tasks should coexist
  lu.assertEquals(#taskQueue.tasks, 1, "Legacy task should still exist")
  lu.assertEquals(#taskQueue.activeTaskComponents, 1, "ECS task component should exist")
  
  -- Switch back to legacy mode
  taskQueue:disableECSMode()
  lu.assertFalse(taskQueue:isECSMode(), "Should be back in legacy mode")
end

function TestSystemIntegration:testConcurrentTaskLimits()
  -- Test that ECS mode respects concurrent task limits
  
  local entityId = MockEntityManager:createEntity()
  local taskQueue = MockTaskQueue.new(entityId)
  taskQueue:enableECSMode()
  taskQueue.maxConcurrentTasks = 2 -- Limit to 2 concurrent tasks
  
  -- Add tasks up to the limit
  local success1 = taskQueue:addMovementTask(MockVec2.new(1, 1))
  local success2 = taskQueue:addMovementTask(MockVec2.new(2, 2))
  lu.assertTrue(success1, "First task should succeed")
  lu.assertTrue(success2, "Second task should succeed")
  lu.assertEquals(#taskQueue.activeTaskComponents, 2, "Should have 2 active tasks")
  
  -- Try to add beyond the limit
  local success3 = taskQueue:addMovementTask(MockVec2.new(3, 3))
  lu.assertFalse(success3, "Third task should fail due to limit")
  lu.assertEquals(#taskQueue.activeTaskComponents, 2, "Should still have only 2 active tasks")
end

function TestSystemIntegration:testSystemUpdateOrder()
  -- Test that systems can run in the correct order without conflicts
  
  local entityId = MockEntityManager:createEntity()
  MockEntityManager:addComponent(entityId, MockComponentType.POSITION, MockVec2.new(0, 0))
  
  local taskQueue = MockTaskQueue.new(entityId)
  taskQueue:enableECSMode()
  MockEntityManager:addComponent(entityId, MockComponentType.TASKQUEUE, taskQueue)
  
  -- Add a movement task
  taskQueue:addMovementTask(MockVec2.new(10, 10))
  MockEntityManager:addComponent(entityId, MockComponentType.MOVEMENT_TASK, {
    targetPosition = MockVec2.new(10, 10),
    requiredDistance = 0.5,
    movementSpeed = 1.0
  })
  
  -- Simulate typical game loop order:
  -- 1. Input system (already handled - task was assigned)
  -- 2. Task execution system (would process dependencies)
  -- 3. Movement system
  local movementSystem = MockMovementSystem.new()
  movementSystem:update(0.016)
  
  -- 4. Position system (would handle physics/collision, but no conflicts expected)
  
  -- Verify no conflicts occurred and entity moved
  local position = MockEntityManager:getComponent(entityId, MockComponentType.POSITION)
  lu.assertEquals(position.x, 10)
  lu.assertEquals(position.y, 10)
  lu.assertEquals(movementSystem.processedEntities, 1)
end

function TestSystemIntegration:testInputToTaskAssignment()
  -- Test that input system can properly assign tasks using new architecture
  
  local entityId = MockEntityManager:createEntity()
  MockEntityManager:addComponent(entityId, MockComponentType.POSITION, MockVec2.new(0, 0))
  MockEntityManager:addComponent(entityId, MockComponentType.SELECTED, true)
  MockEntityManager:addComponent(entityId, MockComponentType.SPEEDSTAT, 1.0)
  
  local taskQueue = MockTaskQueue.new(entityId)
  MockEntityManager:addComponent(entityId, MockComponentType.TASKQUEUE, taskQueue)
  
  -- Simulate right-click input handler (like RightClickMenu logic)
  local targetPosition = MockVec2.new(8, 8)
  
  -- Test ECS mode path
  taskQueue:enableECSMode()
  if taskQueue.isECSMode and taskQueue:isECSMode() then
    local success = taskQueue:addMovementTask(targetPosition)
    lu.assertTrue(success, "ECS mode task assignment should succeed")
    lu.assertEquals(#taskQueue.activeTaskComponents, 1, "Should have ECS task")
  end
  
  -- Reset and test legacy mode path
  taskQueue:reset()
  taskQueue:disableECSMode()
  if not (taskQueue.isECSMode and taskQueue:isECSMode()) then
    taskQueue:push(MockTask.new(MockTaskType.MOVETO, targetPosition))
    lu.assertEquals(#taskQueue.tasks, 1, "Should have legacy task")
    lu.assertTrue(taskQueue.tasks[1].isLegacy, "Task should be marked as legacy")
  end
end

function TestSystemIntegration:testPerformanceWithMixedModes()
  -- Test performance characteristics with mixed ECS/legacy entities
  
  local ecsEntities = {}
  local legacyEntities = {}
  
  -- Create 5 ECS entities
  for i = 1, 5 do
    local entityId = MockEntityManager:createEntity()
    MockEntityManager:addComponent(entityId, MockComponentType.POSITION, MockVec2.new(i, i))
    
    local taskQueue = MockTaskQueue.new(entityId)
    taskQueue:enableECSMode()
    taskQueue:addMovementTask(MockVec2.new(i + 10, i + 10))
    MockEntityManager:addComponent(entityId, MockComponentType.TASKQUEUE, taskQueue)
    MockEntityManager:addComponent(entityId, MockComponentType.MOVEMENT_TASK, {
      targetPosition = MockVec2.new(i + 10, i + 10)
    })
    
    table.insert(ecsEntities, entityId)
  end
  
  -- Create 5 legacy entities
  for i = 1, 5 do
    local entityId = MockEntityManager:createEntity()
    MockEntityManager:addComponent(entityId, MockComponentType.POSITION, MockVec2.new(i, i))
    
    local taskQueue = MockTaskQueue.new(entityId)
    -- Keep in legacy mode (default)
    taskQueue:push(MockTask.new(MockTaskType.MOVETO, MockVec2.new(i + 10, i + 10)))
    MockEntityManager:addComponent(entityId, MockComponentType.TASKQUEUE, taskQueue)
    
    table.insert(legacyEntities, entityId)
  end
  
  -- Process ECS entities
  local movementSystem = MockMovementSystem.new()
  movementSystem:update(0.016)
  
  -- Verify ECS entities were processed
  lu.assertEquals(movementSystem.processedEntities, 5, "Should process 5 ECS entities")
  lu.assertEquals(movementSystem.completedMovements, 5, "Should complete 5 ECS movements")
  
  -- Verify both ECS and legacy entities coexist
  lu.assertEquals(#ecsEntities, 5, "Should have 5 ECS entities")
  lu.assertEquals(#legacyEntities, 5, "Should have 5 legacy entities") 
  
  -- Total entities should be 10
  local totalEntities = 0
  for _ in pairs(MockEntityManager.entities) do
    totalEntities = totalEntities + 1
  end
  lu.assertEquals(totalEntities, 10, "Should have 10 total entities")
end

-- Run the tests
local runner = lu.LuaUnit.new()
runner:setOutputType("text")
os.exit(runner:runSuite())