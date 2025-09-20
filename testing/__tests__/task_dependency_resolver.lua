package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

-- Load test framework and stubs
local luaunit = require("testing.luaunit")

-- Load Love2D stub
require("testing.loveStub")

-- Load project modules
local Logger = {
  info = function(self, msg) end,
  warn = function(self, msg) end,
  error = function(self, msg) end,
  debug = function(self, msg) end,
}

-- Mock EntityManager for testing
local MockEntityManager = {
  entities = {},
  components = {},
}

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
  if self.components[componentType] then
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

function MockEntityManager:reset()
  self.entities = {}
  self.components = {}
end

-- Mock modules
package.loaded["logger"] = Logger
package.loaded["systems.EntityManager"] = MockEntityManager

-- Load the system under test
local TaskDependencyResolver = require("game.systems.TaskDependencyResolver")
local enums = require("game.utils.enums")

-- Create mock task components for testing
local function createMockPosition(x, y)
  return { x = x, y = y }
end

local function createMockActionTask(targetPos, requiredDistance)
  return {
    target = targetPos,
    requiredDistance = requiredDistance or 1.0,
    estimatedDuration = 5.0,
    isComplete = false,
    getTargetPosition = function(self)
      return self.target
    end,
    isInRange = function(self, entityPos)
      if not entityPos or not self.target then
        return false
      end
      local dx = entityPos.x - self.target.x
      local dy = entityPos.y - self.target.y
      local distance = math.sqrt(dx * dx + dy * dy)
      return distance <= self.requiredDistance
    end,
  }
end

local function createMockMovementTask(targetPos, requiredDistance)
  return {
    targetPosition = targetPos,
    requiredDistance = requiredDistance or 0.5,
    estimatedDuration = 3.0,
    isComplete = false,
    path = { targetPos },
    setPath = function(self, path)
      self.path = path
    end,
  }
end

-- Mock MovementTask module
local MockMovementTask = {
  newFromPool = function(targetPosition, requiredDistance, movementSpeed)
    return createMockMovementTask(targetPosition, requiredDistance)
  end,
}
package.loaded["components.MovementTask"] = MockMovementTask

-- Test Suite
TestTaskDependencyResolver = {}

function TestTaskDependencyResolver:setUp()
  -- Reset all state before each test
  MockEntityManager:reset()
  TaskDependencyResolver.isInitialized = false
  TaskDependencyResolver:init()
end

function TestTaskDependencyResolver:tearDown()
  MockEntityManager:reset()
end

-- Test: Initialization
function TestTaskDependencyResolver:testInitialization()
  TaskDependencyResolver.isInitialized = false
  TaskDependencyResolver:init()

  luaunit.assertTrue(TaskDependencyResolver:isReady())
  luaunit.assertNotNil(TaskDependencyResolver.statistics)
  luaunit.assertEquals(TaskDependencyResolver.statistics.dependenciesResolved, 0)
  luaunit.assertEquals(TaskDependencyResolver.statistics.movementTasksInjected, 0)
end

function TestTaskDependencyResolver:testDoubleInitialization()
  TaskDependencyResolver:init()
  TaskDependencyResolver:init() -- Should warn but not fail
  luaunit.assertTrue(TaskDependencyResolver:isReady())
end

-- Test: Basic dependency resolution
function TestTaskDependencyResolver:testEntityWithinRange()
  local entityId = 1
  local targetPos = createMockPosition(5, 5)
  local entityPos = createMockPosition(5, 5) -- Same position
  local actionTask = createMockActionTask(targetPos, 1.0)

  -- Set up entity with position and action task
  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, entityPos)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, actionTask)

  -- Resolve dependencies
  local resolved, movementAdded =
    TaskDependencyResolver:resolveEntityDependencies(entityId, enums.ComponentType.MINING_TASK)

  luaunit.assertTrue(resolved)
  luaunit.assertFalse(movementAdded)
end

function TestTaskDependencyResolver:testEntityOutOfRange()
  local entityId = 1
  local targetPos = createMockPosition(10, 10)
  local entityPos = createMockPosition(5, 5) -- 5 units away
  local actionTask = createMockActionTask(targetPos, 1.0)

  -- Set up entity with position and action task
  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, entityPos)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, actionTask)

  -- Resolve dependencies
  local resolved, movementAdded =
    TaskDependencyResolver:resolveEntityDependencies(entityId, enums.ComponentType.MINING_TASK)

  luaunit.assertTrue(resolved)
  luaunit.assertTrue(movementAdded)

  -- Verify movement task was added
  local movementTask = MockEntityManager:getComponent(entityId, enums.ComponentType.MOVEMENT_TASK)
  luaunit.assertNotNil(movementTask)
  luaunit.assertEquals(movementTask.targetPosition.x, targetPos.x)
  luaunit.assertEquals(movementTask.targetPosition.y, targetPos.y)
end

-- Test: Existing valid movement task
function TestTaskDependencyResolver:testExistingValidMovementTask()
  local entityId = 1
  local targetPos = createMockPosition(10, 10)
  local entityPos = createMockPosition(5, 5)
  local actionTask = createMockActionTask(targetPos, 1.0)
  local existingMovement = createMockMovementTask(targetPos, 1.0)

  -- Set up entity with position, action task, and existing movement
  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, entityPos)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, actionTask)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MOVEMENT_TASK, existingMovement)

  -- Resolve dependencies
  local resolved, movementAdded =
    TaskDependencyResolver:resolveEntityDependencies(entityId, enums.ComponentType.MINING_TASK)

  luaunit.assertTrue(resolved)
  luaunit.assertFalse(movementAdded) -- Should not add new movement task
end

-- Test: Existing invalid movement task
function TestTaskDependencyResolver:testExistingInvalidMovementTask()
  local entityId = 1
  local targetPos = createMockPosition(10, 10)
  local wrongTargetPos = createMockPosition(15, 15)
  local entityPos = createMockPosition(5, 5)
  local actionTask = createMockActionTask(targetPos, 1.0)
  local invalidMovement = createMockMovementTask(wrongTargetPos, 1.0)

  -- Set up entity with position, action task, and invalid movement
  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, entityPos)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, actionTask)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MOVEMENT_TASK, invalidMovement)

  -- Resolve dependencies
  local resolved, movementAdded =
    TaskDependencyResolver:resolveEntityDependencies(entityId, enums.ComponentType.MINING_TASK)

  luaunit.assertTrue(resolved)
  luaunit.assertTrue(movementAdded)

  -- Verify new movement task was added with correct target
  local movementTask = MockEntityManager:getComponent(entityId, enums.ComponentType.MOVEMENT_TASK)
  luaunit.assertNotNil(movementTask)
  luaunit.assertEquals(movementTask.targetPosition.x, targetPos.x)
  luaunit.assertEquals(movementTask.targetPosition.y, targetPos.y)
end

-- Test: Batch dependency resolution
function TestTaskDependencyResolver:testBatchDependencyResolution()
  -- Create multiple entities with different scenarios
  local entity1 = 1 -- Within range
  local entity2 = 2 -- Out of range
  local entity3 = 3 -- No position

  local targetPos = createMockPosition(10, 10)
  local actionTask1 = createMockActionTask(targetPos, 1.0)
  local actionTask2 = createMockActionTask(targetPos, 1.0)
  local actionTask3 = createMockActionTask(targetPos, 1.0)

  -- Set up entities
  MockEntityManager:addComponent(entity1, enums.ComponentType.POSITION, createMockPosition(10, 10))
  MockEntityManager:addComponent(entity1, enums.ComponentType.MINING_TASK, actionTask1)

  MockEntityManager:addComponent(entity2, enums.ComponentType.POSITION, createMockPosition(5, 5))
  MockEntityManager:addComponent(entity2, enums.ComponentType.MINING_TASK, actionTask2)

  MockEntityManager:addComponent(entity3, enums.ComponentType.MINING_TASK, actionTask3) -- No position

  -- Run batch resolution
  TaskDependencyResolver:resolveDependencies()

  -- Check statistics
  local stats = TaskDependencyResolver:getStatistics()
  luaunit.assertEquals(stats.entitiesAnalyzed, 3)
  luaunit.assertEquals(stats.dependenciesResolved, 2) -- entity1 and entity2
  luaunit.assertEquals(stats.movementTasksInjected, 1) -- Only entity2
end

-- Test: Entity requirement checking
function TestTaskDependencyResolver:testEntityRequiresMovement()
  local entityId = 1
  local targetPos = createMockPosition(10, 10)
  local entityPos = createMockPosition(5, 5)
  local actionTask = createMockActionTask(targetPos, 1.0)

  -- Set up entity
  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, entityPos)
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, actionTask)

  luaunit.assertTrue(TaskDependencyResolver:entityRequiresMovement(entityId))

  -- Move entity closer
  entityPos.x = 10
  entityPos.y = 10
  luaunit.assertFalse(TaskDependencyResolver:entityRequiresMovement(entityId))
end

-- Test: Movement task validation
function TestTaskDependencyResolver:testMovementTaskValidation()
  local targetPos = createMockPosition(10, 10)
  local correctMovement = createMockMovementTask(targetPos, 1.0)
  local incorrectMovement = createMockMovementTask(createMockPosition(15, 15), 1.0)

  luaunit.assertTrue(TaskDependencyResolver:isMovementTaskValid(correctMovement, targetPos, 1.0))
  luaunit.assertFalse(TaskDependencyResolver:isMovementTaskValid(incorrectMovement, targetPos, 1.0))
  luaunit.assertFalse(TaskDependencyResolver:isMovementTaskValid(nil, targetPos, 1.0))
  luaunit.assertFalse(TaskDependencyResolver:isMovementTaskValid(correctMovement, nil, 1.0))
end

-- Test: Get entities requiring movement
function TestTaskDependencyResolver:testGetEntitiesRequiringMovement()
  local entity1 = 1 -- Requires movement
  local entity2 = 2 -- Does not require movement
  local entity3 = 3 -- No position

  local targetPos = createMockPosition(10, 10)

  -- Set up entities
  MockEntityManager:addComponent(entity1, enums.ComponentType.POSITION, createMockPosition(5, 5))
  MockEntityManager:addComponent(entity1, enums.ComponentType.MINING_TASK, createMockActionTask(targetPos, 1.0))

  MockEntityManager:addComponent(entity2, enums.ComponentType.POSITION, createMockPosition(10, 10))
  MockEntityManager:addComponent(entity2, enums.ComponentType.MINING_TASK, createMockActionTask(targetPos, 1.0))

  MockEntityManager:addComponent(entity3, enums.ComponentType.MINING_TASK, createMockActionTask(targetPos, 1.0))

  local entitiesRequiringMovement = TaskDependencyResolver:getEntitiesRequiringMovement()
  luaunit.assertEquals(#entitiesRequiringMovement, 1)
  luaunit.assertEquals(entitiesRequiringMovement[1], entity1)
end

-- Test: Dependency chain analysis
function TestTaskDependencyResolver:testDependencyChainAnalysis()
  local entityId = 1
  local targetPos1 = createMockPosition(10, 10)
  local targetPos2 = createMockPosition(12, 12) -- Close to first target
  local targetPos3 = createMockPosition(20, 20) -- Far from first target

  -- Set up entity with multiple action tasks
  MockEntityManager:addComponent(entityId, enums.ComponentType.POSITION, createMockPosition(5, 5))
  MockEntityManager:addComponent(entityId, enums.ComponentType.MINING_TASK, createMockActionTask(targetPos1, 1.0))
  MockEntityManager:addComponent(entityId, enums.ComponentType.CONSTRUCTION_TASK, createMockActionTask(targetPos2, 1.0))
  MockEntityManager:addComponent(entityId, enums.ComponentType.CLEANING_TASK, createMockActionTask(targetPos3, 1.0))

  local analysis = TaskDependencyResolver:analyzeDependencyChains(entityId)

  luaunit.assertFalse(analysis.hasMovementTask)
  luaunit.assertEquals(#analysis.actionTasks, 3)
  luaunit.assertTrue(analysis.conflictingTargets) -- targetPos3 is far from targetPos1
  luaunit.assertTrue(analysis.totalEstimatedTime > 0)
end

-- Test: Statistics functionality
function TestTaskDependencyResolver:testStatistics()
  local stats = TaskDependencyResolver:getStatistics()
  luaunit.assertNotNil(stats.dependenciesResolved)
  luaunit.assertNotNil(stats.movementTasksInjected)
  luaunit.assertNotNil(stats.entitiesAnalyzed)
  luaunit.assertNotNil(stats.resolveTime)
  luaunit.assertNotNil(stats.averageResolveTimePerEntity)

  -- Reset and verify
  TaskDependencyResolver:resetStatistics()
  stats = TaskDependencyResolver:getStatistics()
  luaunit.assertEquals(stats.dependenciesResolved, 0)
  luaunit.assertEquals(stats.movementTasksInjected, 0)
  luaunit.assertEquals(stats.entitiesAnalyzed, 0)
  luaunit.assertEquals(stats.resolveTime, 0)
end

-- Test: Action task types
function TestTaskDependencyResolver:testActionTaskTypes()
  local actionTypes = TaskDependencyResolver:getActionTaskTypes()
  luaunit.assertNotNil(actionTypes)
  luaunit.assertTrue(#actionTypes > 0)

  -- Verify expected action types are included
  local hasMinig = false
  local hasConstruction = false
  local hasCleaning = false

  for _, taskType in ipairs(actionTypes) do
    if taskType == enums.ComponentType.MINING_TASK then
      hasMinig = true
    elseif taskType == enums.ComponentType.CONSTRUCTION_TASK then
      hasConstruction = true
    elseif taskType == enums.ComponentType.CLEANING_TASK then
      hasCleaning = true
    end
  end

  luaunit.assertTrue(hasMinig)
  luaunit.assertTrue(hasConstruction)
  luaunit.assertTrue(hasCleaning)
end

-- Test: Error handling
function TestTaskDependencyResolver:testErrorHandling()
  -- Test uninitialized resolver
  TaskDependencyResolver.isInitialized = false
  TaskDependencyResolver:resolveDependencies() -- Should handle gracefully

  TaskDependencyResolver:init()

  -- Test entity without action task
  local entityId = 999
  local resolved, movementAdded =
    TaskDependencyResolver:resolveEntityDependencies(entityId, enums.ComponentType.MINING_TASK)
  luaunit.assertFalse(resolved)
  luaunit.assertFalse(movementAdded)

  -- Test entity without position
  MockEntityManager:addComponent(
    entityId,
    enums.ComponentType.MINING_TASK,
    createMockActionTask(createMockPosition(10, 10), 1.0)
  )
  resolved, movementAdded = TaskDependencyResolver:resolveEntityDependencies(entityId, enums.ComponentType.MINING_TASK)
  luaunit.assertFalse(resolved)
  luaunit.assertFalse(movementAdded)
end

-- Test: Performance with many entities
function TestTaskDependencyResolver:testPerformanceWithManyEntities()
  -- Create 100 entities that need movement
  for i = 1, 100 do
    MockEntityManager:addComponent(i, enums.ComponentType.POSITION, createMockPosition(1, 1))
    MockEntityManager:addComponent(
      i,
      enums.ComponentType.MINING_TASK,
      createMockActionTask(createMockPosition(10, 10), 1.0)
    )
  end

  local startTime = love.timer.getTime()
  TaskDependencyResolver:resolveDependencies()
  local endTime = love.timer.getTime()

  local stats = TaskDependencyResolver:getStatistics()
  luaunit.assertEquals(stats.entitiesAnalyzed, 100)
  luaunit.assertEquals(stats.dependenciesResolved, 100)
  luaunit.assertEquals(stats.movementTasksInjected, 100)

  -- Verify performance (should complete in reasonable time)
  local totalTime = endTime - startTime
  luaunit.assertTrue(totalTime < 1.0) -- Should complete in less than 1 second
end

-- Run the tests
if luaunit then
  os.exit(luaunit.LuaUnit.run())
end
