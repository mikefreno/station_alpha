-- TaskManager ECS Bridge Tests
local luaunit = require("luaunit")

-- Mock dependencies
package.path = package.path .. ";game/?.lua"
local enum = {
  ComponentType = {
    TASKQUEUE = 1,
    SCHEDULE = 2,
    MOVEMENT_TASK = 3,
    MINING_TASK = 4,
    CONSTRUCTION_TASK = 5,
    CLEANING_TASK = 6,
  },
  TaskType = {
    MOVETO = 1,
    MINE = 2,
    BUILD = 3,
    CLEAN = 4,
  },
}

-- Mock Logger
local Logger = {
  info = function(msg)
    print("INFO: " .. msg)
  end,
  warn = function(msg)
    print("WARN: " .. msg)
  end,
  error = function(msg)
    print("ERROR: " .. msg)
  end,
  debug = function(msg) end, -- Silent for tests
}

-- Mock EntityManager
EntityManager = {
  entities = {},
  getComponent = function(entity, componentType)
    return nil
  end,
  addComponent = function(entity, componentType, component)
    return true
  end,
  removeComponent = function(entity, componentType)
    return true
  end,
  query = function(componentType)
    return {}
  end,
}

-- Mock love.timer
love = {
  timer = {
    getTime = function()
      return 0
    end,
  },
}

-- Mock Vec2
local Vec2 = {}

-- Mock Task
local Task = {
  new = function(taskType, target)
    return {
      type = taskType,
      target = target,
    }
  end,
}

-- Mock TaskExecutionSystem
local TaskExecutionSystem = {
  isInitialized = false,
  init = function(self)
    self.isInitialized = true
  end,
  update = function(self, dt) end,
  assignTask = function(self, entity, component, priority)
    return true
  end,
}

-- Mock TaskComponentPool
local TaskComponentPool = {
  pools = {},
  init = function(self, gameTime) end,
  acquire = function(self, componentType)
    return {
      setTarget = function(self, target)
        self.target = target
      end,
      getComponentType = function()
        return componentType
      end,
    }
  end,
}

-- Mock require function for TaskManager dependencies
local original_require = require
_G.require = function(path)
  if path == "game.utils.enums" then
    return enum
  elseif path == "game.components.Task" then
    return Task
  elseif path == "game.utils.Vec2" then
    return Vec2
  elseif path == "logger" then
    return Logger
  elseif path == "game.systems.TaskExecutionSystem" then
    return TaskExecutionSystem
  elseif path == "game.systems.TaskComponentPool" then
    return TaskComponentPool
  else
    return original_require(path)
  end
end

-- Load TaskManager
local TaskManager = require("game.systems.TaskManager")

-- Test Cases
local TestTaskManagerECSBridge = {}

function TestTaskManagerECSBridge:setUp()
  self.taskManager = TaskManager.new()
end

function TestTaskManagerECSBridge:test_new_creates_taskmanager_with_ecs_fields()
  luaunit.assertNotNil(self.taskManager)
  luaunit.assertFalse(self.taskManager.ecsMode)
  luaunit.assertNil(self.taskManager.taskExecutionSystem)
  luaunit.assertNil(self.taskManager.taskComponentPool)
end

function TestTaskManagerECSBridge:test_isECSMode_returns_false_by_default()
  luaunit.assertFalse(self.taskManager:isECSMode())
end

function TestTaskManagerECSBridge:test_enableECSMode_initializes_ecs_systems()
  self.taskManager:enableECSMode()

  luaunit.assertTrue(self.taskManager:isECSMode())
  luaunit.assertNotNil(self.taskManager.taskExecutionSystem)
  luaunit.assertNotNil(self.taskManager.taskComponentPool)
  luaunit.assertTrue(self.taskManager.taskExecutionSystem.isInitialized)
end

function TestTaskManagerECSBridge:test_disableECSMode_reverts_to_legacy()
  -- First enable ECS mode
  self.taskManager:enableECSMode()
  luaunit.assertTrue(self.taskManager:isECSMode())

  -- Then disable it
  self.taskManager:disableECSMode()
  luaunit.assertFalse(self.taskManager:isECSMode())
  luaunit.assertNil(self.taskManager.taskExecutionSystem)
  luaunit.assertNil(self.taskManager.taskComponentPool)
end

function TestTaskManagerECSBridge:test_createECSTask_fails_without_ecs_mode()
  local success = self.taskManager:createECSTask(enum.TaskType.MOVETO, { x = 1, y = 1 }, 1)
  luaunit.assertFalse(success)
end

function TestTaskManagerECSBridge:test_createECSTask_succeeds_with_ecs_mode()
  self.taskManager:enableECSMode()

  local success = self.taskManager:createECSTask(enum.TaskType.MOVETO, { x = 1, y = 1 }, 1)
  luaunit.assertTrue(success)
end

function TestTaskManagerECSBridge:test_convertLegacyTask_fails_without_ecs_mode()
  local legacyTask = Task.new(enum.TaskType.MOVETO, { x = 1, y = 1 })
  local success = self.taskManager:convertLegacyTask(legacyTask, 1)
  luaunit.assertFalse(success)
end

function TestTaskManagerECSBridge:test_convertLegacyTask_succeeds_with_ecs_mode()
  self.taskManager:enableECSMode()

  local legacyTask = Task.new(enum.TaskType.MOVETO, { x = 1, y = 1 })
  local success = self.taskManager:convertLegacyTask(legacyTask, 1)
  luaunit.assertTrue(success)
end

function TestTaskManagerECSBridge:test_update_uses_ecs_system_when_enabled()
  -- Mock the TaskExecutionSystem update to track calls
  local updateCalled = false
  TaskExecutionSystem.update = function(self, dt)
    updateCalled = true
  end

  self.taskManager:enableECSMode()
  self.taskManager:update(0.016)

  luaunit.assertTrue(updateCalled)
end

-- Run tests
if arg and arg[0] == "testing/__tests__/task_manager_ecs_bridge.lua" then
  os.exit(luaunit.LuaUnit.run())
end

return TestTaskManagerECSBridge
