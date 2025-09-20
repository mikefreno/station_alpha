package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua;./game/adapters/?.lua"

local luaunit = require("testing.luaunit")
Logger = require("logger")

-- Import modules
local TaskAdapter = require("game.adapters.TaskAdapter")
local Task = require("game.components.Task")
local enums = require("game.utils.enums")
local Vec2 = require("game.utils.Vec2")

local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

-- Test class for basic TaskAdapter functionality
TestTaskAdapterBasic = {}

function TestTaskAdapterBasic:setUp()
  -- Set up logger for testing
  Logger.level = "ERROR" -- Suppress debug messages during tests
end

-- Test: canConvert validation - Core functionality tests
function TestTaskAdapterBasic:test_canConvert_validMovementTask()
  local legacyTask = Task.new(TaskType.MOVETO, Vec2.new(10, 20))
  local canConvert, error = TaskAdapter:canConvert(legacyTask)
  
  luaunit.assertTrue(canConvert)
  luaunit.assertNil(error)
end

function TestTaskAdapterBasic:test_canConvert_validMiningTask()
  local legacyTask = Task.new(TaskType.MINE, Vec2.new(5, 15))
  local canConvert, error = TaskAdapter:canConvert(legacyTask)
  
  luaunit.assertTrue(canConvert)
  luaunit.assertNil(error)
end

function TestTaskAdapterBasic:test_canConvert_nilTask()
  local canConvert, error = TaskAdapter:canConvert(nil)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertEquals(error, "Legacy task is nil")
end

function TestTaskAdapterBasic:test_canConvert_missingType()
  local invalidTask = { target = Vec2.new(1, 1) }
  local canConvert, error = TaskAdapter:canConvert(invalidTask)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertEquals(error, "Legacy task missing type field")
end

function TestTaskAdapterBasic:test_canConvert_unsupportedType()
  local invalidTask = { type = 999, target = Vec2.new(1, 1) }
  local canConvert, error = TaskAdapter:canConvert(invalidTask)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertStrContains(error, "Unsupported task type")
end

function TestTaskAdapterBasic:test_canConvert_missingTarget()
  local invalidTask = { type = TaskType.MOVETO }
  local canConvert, error = TaskAdapter:canConvert(invalidTask)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertEquals(error, "Legacy task missing target field")
end

function TestTaskAdapterBasic:test_canConvert_invalidMovementTarget()
  local invalidTask = { type = TaskType.MOVETO, target = "invalid" }
  local canConvert, error = TaskAdapter:canConvert(invalidTask)
  
  luaunit.assertFalse(canConvert)
  luaunit.assertStrContains(error, "MOVETO task requires valid Vec2 target")
end

-- Test: utility functions
function TestTaskAdapterBasic:test_getTaskTypeFromComponent()
  luaunit.assertEquals(TaskAdapter:getTaskTypeFromComponent(ComponentType.MOVEMENT_TASK), TaskType.MOVETO)
  luaunit.assertEquals(TaskAdapter:getTaskTypeFromComponent(ComponentType.MINING_TASK), TaskType.MINE)
  luaunit.assertEquals(TaskAdapter:getTaskTypeFromComponent(ComponentType.CONSTRUCTION_TASK), TaskType.CONSTRUCT)
  luaunit.assertEquals(TaskAdapter:getTaskTypeFromComponent(ComponentType.CLEANING_TASK), TaskType.CLEAN)
  luaunit.assertNil(TaskAdapter:getTaskTypeFromComponent(999))
end

function TestTaskAdapterBasic:test_getComponentTypeFromTask()
  luaunit.assertEquals(TaskAdapter:getComponentTypeFromTask(TaskType.MOVETO), ComponentType.MOVEMENT_TASK)
  luaunit.assertEquals(TaskAdapter:getComponentTypeFromTask(TaskType.MINE), ComponentType.MINING_TASK)
  luaunit.assertEquals(TaskAdapter:getComponentTypeFromTask(TaskType.CONSTRUCT), ComponentType.CONSTRUCTION_TASK)
  luaunit.assertEquals(TaskAdapter:getComponentTypeFromTask(TaskType.CLEAN), ComponentType.CLEANING_TASK)
  luaunit.assertNil(TaskAdapter:getComponentTypeFromTask(999))
end

function TestTaskAdapterBasic:test_isTaskTypeSupported()
  luaunit.assertTrue(TaskAdapter:isTaskTypeSupported(TaskType.MOVETO))
  luaunit.assertTrue(TaskAdapter:isTaskTypeSupported(TaskType.MINE))
  luaunit.assertTrue(TaskAdapter:isTaskTypeSupported(TaskType.CONSTRUCT))
  luaunit.assertTrue(TaskAdapter:isTaskTypeSupported(TaskType.CLEAN))
  luaunit.assertFalse(TaskAdapter:isTaskTypeSupported(999))
end

function TestTaskAdapterBasic:test_isComponentTypeSupported()
  luaunit.assertTrue(TaskAdapter:isComponentTypeSupported(ComponentType.MOVEMENT_TASK))
  luaunit.assertTrue(TaskAdapter:isComponentTypeSupported(ComponentType.MINING_TASK))
  luaunit.assertTrue(TaskAdapter:isComponentTypeSupported(ComponentType.CONSTRUCTION_TASK))
  luaunit.assertTrue(TaskAdapter:isComponentTypeSupported(ComponentType.CLEANING_TASK))
  luaunit.assertFalse(TaskAdapter:isComponentTypeSupported(999))
end

function TestTaskAdapterBasic:test_getConversionStats()
  local stats = TaskAdapter:getConversionStats()
  
  luaunit.assertNotNil(stats)
  luaunit.assertEquals(stats.supportedTaskTypes, 4)
  luaunit.assertEquals(stats.supportedComponentTypes, 4)
  luaunit.assertNotNil(stats.taskTypeMapping)
  luaunit.assertNotNil(stats.componentTypeMapping)
end

-- Test mapping consistency
function TestTaskAdapterBasic:test_mappingConsistency()
  local taskTypes = { TaskType.MOVETO, TaskType.MINE, TaskType.CONSTRUCT, TaskType.CLEAN }
  
  for _, taskType in ipairs(taskTypes) do
    -- Forward mapping
    local componentType = TaskAdapter:getComponentTypeFromTask(taskType)
    luaunit.assertNotNil(componentType, "No component type for task " .. taskType)
    
    -- Reverse mapping should give us back the original
    local backToTask = TaskAdapter:getTaskTypeFromComponent(componentType)
    luaunit.assertEquals(backToTask, taskType, "Mapping inconsistency for task " .. taskType)
  end
end

-- Test all supported task types validation
function TestTaskAdapterBasic:test_allSupportedTaskTypesValidate()
  local taskTypes = { TaskType.MOVETO, TaskType.MINE, TaskType.CONSTRUCT, TaskType.CLEAN }
  
  for _, taskType in ipairs(taskTypes) do
    local legacyTask = Task.new(taskType, Vec2.new(1, 2))
    local canConvert, error = TaskAdapter:canConvert(legacyTask)
    
    luaunit.assertTrue(canConvert, "Task type " .. taskType .. " should be convertible")
    luaunit.assertNil(error, "Task type " .. taskType .. " validation should not error")
  end
end

-- Run the tests
if arg and arg[0] == "testing/__tests__/task_adapter_basic.lua" then
  os.exit(luaunit.LuaUnit.run())
end

return TestTaskAdapterBasic