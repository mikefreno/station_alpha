package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua;./game/adapters/?.lua"

local luaunit = require("testing.luaunit")
local loveStub = require("testing.loveStub")

-- Setup love2d environment
love = loveStub
Logger = require("logger")

-- Import modules
local TaskAdapter = require("game.adapters.TaskAdapter")
local Task = require("game.components.Task")
local enums = require("game.utils.enums")
local Vec2 = require("game.utils.Vec2")
local Logger = require("logger")

-- Import task components for testing
local MovementTask = require("game.components.MovementTask")
local MiningTask = require("game.components.MiningTask") 
local ConstructionTask = require("game.components.ConstructionTask")
local CleaningTask = require("game.components.CleaningTask")

-- Import systems
local TaskComponentPool = require("game.systems.TaskComponentPool")

local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

-- Test class
TestTaskAdapter = {}

function TestTaskAdapter:setUp()
  -- Initialize TaskComponentPool for testing
  TaskComponentPool:init(love.timer.getTime())
  
  -- Set up logger for testing
  Logger.level = "DEBUG"
end

function TestTaskAdapter:tearDown()
  -- Clean up pools after each test
  if TaskComponentPool.pools then
    TaskComponentPool:cleanup()
  end
end

-- Test: canConvert validation
function TestTaskAdapter:test_canConvert_validMovementTask()
  local legacyTask = Task.new(TaskType.MOVETO, Vec2.new(10, 20))
  local canConvert, error = TaskAdapter:canConvert(legacyTask)
  
  luaunit.assertTrue(canConvert)
  luaunit.assertNil(error)
end

function TestTaskAdapter:test_canConvert_validMiningTask()
  local legacyTask = Task.new(TaskType.MINE, Vec2.new(5, 15))
  local canConvert, error = TaskAdapter:canConvert(legacyTask)
  
  luaunit.assertTrue(canConvert)
  luaunit.assertNil(error)
end

function TestTaskAdapter:test_canConvert_nilTask()
  local canConvert, error = TaskAdapter:canConvert(nil)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertEquals(error, "Legacy task is nil")
end

function TestTaskAdapter:test_canConvert_missingType()
  local invalidTask = { target = Vec2.new(1, 1) }
  local canConvert, error = TaskAdapter:canConvert(invalidTask)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertEquals(error, "Legacy task missing type field")
end

function TestTaskAdapter:test_canConvert_unsupportedType()
  local invalidTask = { type = 999, target = Vec2.new(1, 1) }
  local canConvert, error = TaskAdapter:canConvert(invalidTask)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertStrContains(error, "Unsupported task type")
end

function TestTaskAdapter:test_canConvert_missingTarget()
  local invalidTask = { type = TaskType.MOVETO }
  local canConvert, error = TaskAdapter:canConvert(invalidTask)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertEquals(error, "Legacy task missing target field")
end

function TestTaskAdapter:test_canConvert_invalidMovementTarget()
  local invalidTask = { type = TaskType.MOVETO, target = "invalid" }
  local canConvert, error = TaskAdapter:canConvert(invalidTask)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertStrContains(error, "MOVETO task requires valid Vec2 target")
end

-- Test: convertToECS
function TestTaskAdapter:test_convertToECS_movementTask()
  local legacyTask = Task.new(TaskType.MOVETO, Vec2.new(10, 20))
  legacyTask.timer = 5.0
  local entityId = 123
  
  local component, componentType, error = TaskAdapter:convertToECS(legacyTask, entityId)
  
  luaunit.assertNotNil(component)
  luaunit.assertEquals(componentType, ComponentType.MOVEMENT_TASK)
  luaunit.assertNil(error)
  
  -- Verify component data
  luaunit.assertEquals(component:getTarget(), legacyTask.target)
  luaunit.assertEquals(component:getEntityId(), entityId)
  luaunit.assertEquals(component:getTimer(), 5.0)
end

function TestTaskAdapter:test_convertToECS_miningTask()
  local legacyTask = Task.new(TaskType.MINE, Vec2.new(5, 15))
  local entityId = 456
  
  local component, componentType, error = TaskAdapter:convertToECS(legacyTask, entityId)
  
  luaunit.assertNotNil(component)
  luaunit.assertEquals(componentType, ComponentType.MINING_TASK)
  luaunit.assertNil(error)
  
  -- Verify component data
  luaunit.assertEquals(component:getTarget(), legacyTask.target)
  luaunit.assertEquals(component:getEntityId(), entityId)
end

function TestTaskAdapter:test_convertToECS_constructionTask()
  local legacyTask = Task.new(TaskType.CONSTRUCT, Vec2.new(8, 12))
  local entityId = 789
  
  local component, componentType, error = TaskAdapter:convertToECS(legacyTask, entityId)
  
  luaunit.assertNotNil(component)
  luaunit.assertEquals(componentType, ComponentType.CONSTRUCTION_TASK)
  luaunit.assertNil(error)
  
  -- Verify component data
  luaunit.assertEquals(component:getTarget(), legacyTask.target)
  luaunit.assertEquals(component:getEntityId(), entityId)
end

function TestTaskAdapter:test_convertToECS_cleaningTask()
  local legacyTask = Task.new(TaskType.CLEAN, Vec2.new(3, 7))
  local entityId = 101
  
  local component, componentType, error = TaskAdapter:convertToECS(legacyTask, entityId)
  
  luaunit.assertNotNil(component)
  luaunit.assertEquals(componentType, ComponentType.CLEANING_TASK)
  luaunit.assertNil(error)
  
  -- Verify component data
  luaunit.assertEquals(component:getTarget(), legacyTask.target)
  luaunit.assertEquals(component:getEntityId(), entityId)
end

function TestTaskAdapter:test_convertToECS_completedTask()
  local legacyTask = Task.new(TaskType.MOVETO, Vec2.new(1, 2))
  legacyTask.isComplete = true
  legacyTask.performer = 999
  local entityId = 123
  
  local component, componentType, error = TaskAdapter:convertToECS(legacyTask, entityId)
  
  luaunit.assertNotNil(component)
  luaunit.assertEquals(componentType, ComponentType.MOVEMENT_TASK)
  luaunit.assertNil(error)
  luaunit.assertTrue(component:isComplete())
end

function TestTaskAdapter:test_convertToECS_invalidTask()
  local invalidTask = nil
  local entityId = 123
  
  local component, componentType, error = TaskAdapter:convertToECS(invalidTask, entityId)
  
  luaunit.assertNil(component)
  luaunit.assertNil(componentType)
  luaunit.assertNotNil(error)
end

-- Test: convertToLegacy
function TestTaskAdapter:test_convertToLegacy_movementTask()
  -- First create an ECS component
  local component = MovementTask.new()
  local target = Vec2.new(15, 25)
  component:setTarget(target)
  component:setEntityId(789)
  component:setTimer(3.5)
  
  local legacyTask, error = TaskAdapter:convertToLegacy(component, ComponentType.MOVEMENT_TASK, 789)
  
  luaunit.assertNotNil(legacyTask)
  luaunit.assertNil(error)
  luaunit.assertEquals(legacyTask.type, TaskType.MOVETO)
  luaunit.assertEquals(legacyTask.target, target)
  luaunit.assertEquals(legacyTask.performer, 789)
  luaunit.assertEquals(legacyTask.timer, 3.5)
end

function TestTaskAdapter:test_convertToLegacy_miningTask()
  local component = MiningTask.new()
  local target = Vec2.new(20, 30)
  component:setTarget(target)
  component:setEntityId(456)
  
  local legacyTask, error = TaskAdapter:convertToLegacy(component, ComponentType.MINING_TASK, 456)
  
  luaunit.assertNotNil(legacyTask)
  luaunit.assertNil(error)
  luaunit.assertEquals(legacyTask.type, TaskType.MINE)
  luaunit.assertEquals(legacyTask.target, target)
  luaunit.assertEquals(legacyTask.performer, 456)
end

function TestTaskAdapter:test_convertToLegacy_completedTask()
  local component = MovementTask.new()
  component:setTarget(Vec2.new(1, 1))
  component:setEntityId(123)
  component:markComplete()
  
  local legacyTask, error = TaskAdapter:convertToLegacy(component, ComponentType.MOVEMENT_TASK, 123)
  
  luaunit.assertNotNil(legacyTask)
  luaunit.assertNil(error)
  luaunit.assertTrue(legacyTask.isComplete)
end

function TestTaskAdapter:test_convertToLegacy_nilComponent()
  local legacyTask, error = TaskAdapter:convertToLegacy(nil, ComponentType.MOVEMENT_TASK, 123)
  
  luaunit.assertNil(legacyTask)
  luaunit.assertEquals(error, "Component is nil")
end

function TestTaskAdapter:test_convertToLegacy_unsupportedComponentType()
  local component = MovementTask.new()
  component:setTarget(Vec2.new(1, 1))
  
  local legacyTask, error = TaskAdapter:convertToLegacy(component, 999, 123)
  
  luaunit.assertNil(legacyTask)
  luaunit.assertStrContains(error, "No legacy task type mapping")
end

-- Test: bidirectional conversion accuracy
function TestTaskAdapter:test_bidirectionalConversion_movementTask()
  local originalTask = Task.new(TaskType.MOVETO, Vec2.new(50, 60))
  originalTask.timer = 10.0
  originalTask.performer = 555
  local entityId = 555
  
  -- Convert to ECS
  local component, componentType, error1 = TaskAdapter:convertToECS(originalTask, entityId)
  luaunit.assertNotNil(component)
  luaunit.assertNil(error1)
  
  -- Convert back to legacy
  local reconvertedTask, error2 = TaskAdapter:convertToLegacy(component, componentType, entityId)
  luaunit.assertNotNil(reconvertedTask)
  luaunit.assertNil(error2)
  
  -- Verify data preservation
  luaunit.assertEquals(reconvertedTask.type, originalTask.type)
  luaunit.assertEquals(reconvertedTask.target.x, originalTask.target.x)
  luaunit.assertEquals(reconvertedTask.target.y, originalTask.target.y)
  luaunit.assertEquals(reconvertedTask.timer, originalTask.timer)
  luaunit.assertEquals(reconvertedTask.performer, originalTask.performer)
end

function TestTaskAdapter:test_bidirectionalConversion_allTaskTypes()
  local taskTypes = {
    { TaskType.MOVETO, ComponentType.MOVEMENT_TASK },
    { TaskType.MINE, ComponentType.MINING_TASK },
    { TaskType.CONSTRUCT, ComponentType.CONSTRUCTION_TASK },
    { TaskType.CLEAN, ComponentType.CLEANING_TASK },
  }
  
  for _, typeMapping in ipairs(taskTypes) do
    local taskType, componentType = typeMapping[1], typeMapping[2]
    local originalTask = Task.new(taskType, Vec2.new(1, 2))
    local entityId = 100
    
    -- Convert to ECS and back
    local component, compType, err1 = TaskAdapter:convertToECS(originalTask, entityId)
    luaunit.assertNotNil(component, "Failed to convert " .. taskType .. " to ECS")
    luaunit.assertEquals(compType, componentType)
    
    local reconvertedTask, err2 = TaskAdapter:convertToLegacy(component, componentType, entityId)
    luaunit.assertNotNil(reconvertedTask, "Failed to convert " .. componentType .. " back to legacy")
    luaunit.assertEquals(reconvertedTask.type, taskType)
  end
end

-- Test: utility functions
function TestTaskAdapter:test_getTaskTypeFromComponent()
  luaunit.assertEquals(TaskAdapter:getTaskTypeFromComponent(ComponentType.MOVEMENT_TASK), TaskType.MOVETO)
  luaunit.assertEquals(TaskAdapter:getTaskTypeFromComponent(ComponentType.MINING_TASK), TaskType.MINE)
  luaunit.assertEquals(TaskAdapter:getTaskTypeFromComponent(ComponentType.CONSTRUCTION_TASK), TaskType.CONSTRUCT)
  luaunit.assertEquals(TaskAdapter:getTaskTypeFromComponent(ComponentType.CLEANING_TASK), TaskType.CLEAN)
  luaunit.assertNil(TaskAdapter:getTaskTypeFromComponent(999))
end

function TestTaskAdapter:test_getComponentTypeFromTask()
  luaunit.assertEquals(TaskAdapter:getComponentTypeFromTask(TaskType.MOVETO), ComponentType.MOVEMENT_TASK)
  luaunit.assertEquals(TaskAdapter:getComponentTypeFromTask(TaskType.MINE), ComponentType.MINING_TASK)
  luaunit.assertEquals(TaskAdapter:getComponentTypeFromTask(TaskType.CONSTRUCT), ComponentType.CONSTRUCTION_TASK)
  luaunit.assertEquals(TaskAdapter:getComponentTypeFromTask(TaskType.CLEAN), ComponentType.CLEANING_TASK)
  luaunit.assertNil(TaskAdapter:getComponentTypeFromTask(999))
end

function TestTaskAdapter:test_isTaskTypeSupported()
  luaunit.assertTrue(TaskAdapter:isTaskTypeSupported(TaskType.MOVETO))
  luaunit.assertTrue(TaskAdapter:isTaskTypeSupported(TaskType.MINE))
  luaunit.assertTrue(TaskAdapter:isTaskTypeSupported(TaskType.CONSTRUCT))
  luaunit.assertTrue(TaskAdapter:isTaskTypeSupported(TaskType.CLEAN))
  luaunit.assertFalse(TaskAdapter:isTaskTypeSupported(999))
end

function TestTaskAdapter:test_isComponentTypeSupported()
  luaunit.assertTrue(TaskAdapter:isComponentTypeSupported(ComponentType.MOVEMENT_TASK))
  luaunit.assertTrue(TaskAdapter:isComponentTypeSupported(ComponentType.MINING_TASK))
  luaunit.assertTrue(TaskAdapter:isComponentTypeSupported(ComponentType.CONSTRUCTION_TASK))
  luaunit.assertTrue(TaskAdapter:isComponentTypeSupported(ComponentType.CLEANING_TASK))
  luaunit.assertFalse(TaskAdapter:isComponentTypeSupported(999))
end

function TestTaskAdapter:test_getConversionStats()
  local stats = TaskAdapter:getConversionStats()
  
  luaunit.assertNotNil(stats)
  luaunit.assertEquals(stats.supportedTaskTypes, 4)
  luaunit.assertEquals(stats.supportedComponentTypes, 4)
  luaunit.assertNotNil(stats.taskTypeMapping)
  luaunit.assertNotNil(stats.componentTypeMapping)
end

-- Test: Error handling and edge cases
function TestTaskAdapter:test_poolExhaustion_gracefulFailure()
  -- This test simulates what happens when the component pool is exhausted
  -- We'll override the acquire method temporarily
  local originalAcquire = TaskComponentPool.acquire
  TaskComponentPool.acquire = function(self, componentType)
    return nil  -- Simulate pool exhaustion
  end
  
  local legacyTask = Task.new(TaskType.MOVETO, Vec2.new(1, 1))
  local component, componentType, error = TaskAdapter:convertToECS(legacyTask, 123)
  
  luaunit.assertNil(component)
  luaunit.assertNil(componentType)
  luaunit.assertStrContains(error, "Failed to acquire component from pool")
  
  -- Restore original method
  TaskComponentPool.acquire = originalAcquire
end

-- Performance test (basic)
function TestTaskAdapter:test_conversionPerformance()
  local startTime = love.timer.getTime()
  local iterations = 100
  
  for i = 1, iterations do
    local legacyTask = Task.new(TaskType.MOVETO, Vec2.new(i, i))
    local component, componentType, error = TaskAdapter:convertToECS(legacyTask, i)
    luaunit.assertNotNil(component)
    
    local reconvertedTask, error2 = TaskAdapter:convertToLegacy(component, componentType, i)
    luaunit.assertNotNil(reconvertedTask)
  end
  
  local endTime = love.timer.getTime()
  local totalTime = endTime - startTime
  
  -- Should complete 100 bidirectional conversions in under 1 second
  luaunit.assertLessThan(totalTime, 1.0, "Conversion performance test failed - took " .. totalTime .. " seconds")
end

-- Run the tests
if arg and arg[0] == "testing/__tests__/task_adapter.lua" then
  love.timer = { getTime = function() return os.clock() end }
  os.exit(luaunit.LuaUnit.run())
end

return TestTaskAdapter