package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
require("testing.loveStub")

-- Mock Logger
Logger = {
  info = function(...) end,
  warn = function(...) end,
  debug = function(...) end,
  error = function(...) end,
}

-- Create a basic mock for EntityManager
local MockEntityManager = {
  entities = {},
  components = {},
  
  createEntity = function(self)
    local id = #self.entities + 1
    self.entities[id] = true
    self.components[id] = {}
    return id
  end,
  
  addComponent = function(self, entityId, componentType, component)
    if not self.components[entityId] then
      self.components[entityId] = {}
    end
    self.components[entityId][componentType] = component
  end,
  
  getComponent = function(self, entityId, componentType)
    if self.components[entityId] then
      return self.components[entityId][componentType]
    end
    return nil
  end,
}

-- Set up global mocks
EntityManager = MockEntityManager

-- Mock Vec2
local Vec2 = { new = function(x, y) return {x = x or 0, y = y or 0} end }

-- Mock enums
local enums = {
  ComponentType = {
    TASKQUEUE = "TASKQUEUE",
    SCHEDULE = "SCHEDULE",
    MOVEMENT_TASK = "MOVEMENT_TASK",
    MINING_TASK = "MINING_TASK",
    CONSTRUCTION_TASK = "CONSTRUCTION_TASK",
    CLEANING_TASK = "CLEANING_TASK",
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
  if path == "game.utils.enums" then
    return enums
  elseif path == "game.utils.Vec2" then
    return Vec2
  elseif path == "logger" then
    return Logger
  elseif path == "game.systems.EntityManager" then
    return MockEntityManager
  else
    return original_require(path)
  end
end

-- Import the components we're testing
local TaskManager = require("game.systems.TaskManager")
local Schedule = require("game.components.Schedule")
local TaskQueue = require("game.components.TaskQueue")

TestLegacyPhaseout = {}

function TestLegacyPhaseout:setUp()
  -- Reset mock state
  MockEntityManager.entities = {}
  MockEntityManager.components = {}
end

function TestLegacyPhaseout:test_taskmanager_defaults_to_ecs_mode()
  local taskManager = TaskManager.new()
  
  luaunit.assertTrue(taskManager:isECSMode(), "TaskManager should default to ECS mode")
  luaunit.assertNotNil(taskManager.taskExecutionSystem, "TaskExecutionSystem should be initialized")
  luaunit.assertNotNil(taskManager.taskComponentPool, "TaskComponentPool should be initialized")
end

function TestLegacyPhaseout:test_schedule_ecs_mode_functionality()
  local schedule = Schedule.new()
  
  -- Test initial state
  luaunit.assertFalse(schedule:isECSMode(), "Schedule should start in legacy mode for backward compatibility")
  
  -- Test enabling ECS mode
  schedule:enableECSMode()
  luaunit.assertTrue(schedule:isECSMode(), "Schedule should be in ECS mode after enableECSMode()")
  
  -- Test disabling ECS mode
  schedule:disableECSMode()
  luaunit.assertFalse(schedule:isECSMode(), "Schedule should be in legacy mode after disableECSMode()")
end

function TestLegacyPhaseout:test_schedule_selectNextTaskType_ecs_method()
  local schedule = Schedule.new()
  schedule:enableECSMode()
  
  -- Set up test data
  schedule:adjustScheduleWeight(enums.TaskType.MINE, 5)
  schedule:adjustScheduleWeight(enums.TaskType.CONSTRUCT, 3)
  
  local openTasks = {
    [enums.TaskType.MINE] = {"mine_target_1", "mine_target_2"},
    [enums.TaskType.CONSTRUCT] = {"construct_target_1"}
  }
  
  -- Test task selection
  local taskType, target = schedule:selectNextTaskType(openTasks)
  luaunit.assertEquals(taskType, enums.TaskType.MINE, "Should select highest priority task type")
  luaunit.assertEquals(target, "mine_target_1", "Should return the first target")
  
  -- Verify task was removed from open tasks
  luaunit.assertEquals(#openTasks[enums.TaskType.MINE], 1, "Task should be removed from open tasks")
end

function TestLegacyPhaseout:test_taskqueue_ecs_mode_compatibility()
  local entity = EntityManager:createEntity()
  local taskQueue = TaskQueue.new(entity)
  
  -- Test initial state (should start in legacy mode for backward compatibility)
  luaunit.assertFalse(taskQueue:isECSMode(), "TaskQueue should start in legacy mode")
  
  -- Test enabling ECS mode
  taskQueue:enableECSMode()
  luaunit.assertTrue(taskQueue:isECSMode(), "TaskQueue should be in ECS mode after enableECSMode()")
end

function TestLegacyPhaseout:test_entity_initialization_ecs_mode()
  -- Simulate entity creation like in main.lua
  local entity = EntityManager:createEntity()
  
  local taskQueue = TaskQueue.new(entity)
  taskQueue:enableECSMode()
  EntityManager:addComponent(entity, enums.ComponentType.TASKQUEUE, taskQueue)
  
  local schedule = Schedule.new()
  schedule:enableECSMode()
  EntityManager:addComponent(entity, enums.ComponentType.SCHEDULE, schedule)
  
  -- Verify components are in ECS mode
  local retrievedTaskQueue = EntityManager:getComponent(entity, enums.ComponentType.TASKQUEUE)
  local retrievedSchedule = EntityManager:getComponent(entity, enums.ComponentType.SCHEDULE)
  
  luaunit.assertTrue(retrievedTaskQueue:isECSMode(), "Retrieved TaskQueue should be in ECS mode")
  luaunit.assertTrue(retrievedSchedule:isECSMode(), "Retrieved Schedule should be in ECS mode")
end

function TestLegacyPhaseout:test_taskmanager_ecs_initialization_no_errors()
  -- Test that TaskManager can be created without errors
  local success, taskManager = pcall(TaskManager.new)
  
  luaunit.assertTrue(success, "TaskManager.new() should not throw errors")
  luaunit.assertNotNil(taskManager, "TaskManager should be created successfully")
  luaunit.assertTrue(taskManager:isECSMode(), "TaskManager should be in ECS mode")
end

function TestLegacyPhaseout:test_backward_compatibility_preserved()
  local schedule = Schedule.new()
  
  -- Test that legacy mode still works
  luaunit.assertFalse(schedule:isECSMode(), "Schedule should start in legacy mode")
  
  local openTasks = {
    [enums.TaskType.MINE] = {{type = enums.TaskType.MINE, target = "legacy_target"}}
  }
  
  schedule:adjustScheduleWeight(enums.TaskType.MINE, 5)
  
  -- This should work in legacy mode
  local selectedTask = schedule:selectNextTask(openTasks)
  luaunit.assertNotNil(selectedTask, "Legacy selectNextTask should still work")
end

function TestLegacyPhaseout:test_deprecation_warnings_logged()
  local warnings = {}
  local originalWarn = Logger.warn
  Logger.warn = function(self, msg, ...)
    -- Handle both Logger.warn(msg) and Logger:warn(msg) calls
    if type(self) == "string" then
      -- Called as Logger.warn(msg, ...)
      table.insert(warnings, self)
    else
      -- Called as Logger:warn(msg, ...) where self is the Logger table
      table.insert(warnings, tostring(msg))
    end
  end
  
  local schedule = Schedule.new()
  schedule:enableECSMode()
  
  -- This should trigger deprecation warning in ECS mode
  schedule:selectNextTask({})
  
  luaunit.assertTrue(#warnings > 0, "Deprecation warning should be logged")
  if #warnings > 0 then
    luaunit.assertStrContains(tostring(warnings[1]), "selectNextTask", "Warning should mention the deprecated method")
  end
  
  -- Restore original logger
  Logger.warn = originalWarn
end

-- Run the tests
luaunit.LuaUnit.verbosity = 2
os.exit(luaunit.LuaUnit:runSuite())