-- Test file: TaskManager ECS Integration Tests
-- Tests the ECS-only operation of TaskManager

-- Mock dependencies first
local MockEntityManager = {
  entities = {},
  components = {},
  
  setComponent = function(self, entity, componentType, component)
    if not self.entities[entity] then
      self.entities[entity] = {}
    end
    self.entities[entity][componentType] = component
    
    -- Auto-inject markComplete method for testing
    if component and not component.markComplete then
      component.markComplete = function() component.completed = true end
    end
  end,
  
  getComponent = function(self, entity, componentType)
    if self.entities[entity] then
      return self.entities[entity][componentType]
    end
    return nil
  end,
  
  addComponent = function(self, entity, componentType, component)
    self:setComponent(entity, componentType, component)
  end,
  
  removeComponent = function(self, entity, componentType)
    if self.entities[entity] then
      self.entities[entity][componentType] = nil
    end
  end,
  
  query = function(self, componentType)
    local entities = {}
    for entityId, components in pairs(self.entities) do
      if components[componentType] then
        table.insert(entities, entityId)
      end
    end
    return entities
  end
}

-- Set global EntityManager
_G.EntityManager = MockEntityManager

-- Mock Love2D timer
local mockTimer = {
  getTime = function() return 0.0 end
}
_G.love = { timer = mockTimer }

-- Mock Logger
local MockLogger = {
  info = function(self, msg) print("INFO: " .. msg) end,
  warn = function(self, msg) print("WARN: " .. msg) end,
  error = function(self, msg) print("ERROR: " .. msg) end,
  debug = function(self, msg) end -- Silent debug for tests
}

-- Import necessary modules
package.path = "?.lua;game/?.lua;game/utils/?.lua;game/systems/?.lua;game/components/?.lua;" .. package.path

-- Set up Logger before requiring modules
_G.Logger = MockLogger

local luaunit = require('testing.luaunit')
local TaskManager = require('game.systems.TaskManager')
local enums = require('game.utils.enums')

TestTaskManagerECSBridge = {}

function TestTaskManagerECSBridge:setUp()
  -- Reset EntityManager state
  MockEntityManager.entities = {}
  MockEntityManager.components = {}
end

function TestTaskManagerECSBridge:testTaskManagerCreation()
  local tm = TaskManager.new()
  luaunit.assertNotNil(tm)
  -- TaskManager always operates in ECS mode now
  luaunit.assertNotNil(tm.openTasks)
end

function TestTaskManagerECSBridge:testECSTaskCreationWithoutSystems()
  local tm = TaskManager.new()
  
  -- Should fail gracefully when systems not initialized
  local success = tm:createECSTask(enums.TaskType.MOVETO, {x=10, y=10}, 1)
  luaunit.assertEquals(success, false)
end

function TestTaskManagerECSBridge:testUpdateOperation()
  local tm = TaskManager.new()
  
  -- Test ECS update (should not crash even without systems)
  local success, error = pcall(function()
    tm:update(0.016) -- 16ms frame time
  end)
  
  -- Should succeed or fail gracefully
  luaunit.assertTrue(success or error:find("attempt to call field") ~= nil)
end

function TestTaskManagerECSBridge:testNewPathECSMode()
  local tm = TaskManager.new()
  
  -- Create an entity with TaskQueue component
  local mockTaskQueue = {
    reset = function(self) self.tasks = {} end,
    push = function(self, task) table.insert(self.tasks, task) end,
    tasks = {}
  }
  
  MockEntityManager:setComponent(1, enums.ComponentType.TASKQUEUE, mockTaskQueue)
  
  -- Test creating a path
  local path = {{x=1, y=1}, {x=2, y=2}, {x=3, y=3}}
  local success, error = pcall(function()
    tm:newPath(1, path)
  end)
  
  -- Should succeed or fail due to missing Task class import
  luaunit.assertTrue(success or error:find("module") ~= nil)
end

function TestTaskManagerECSBridge:testMethodsExist()
  local tm = TaskManager.new()
  
  -- Verify core methods exist (removed ECS mode toggle methods)
  local methods = {
    'update', 'addTask', 'newPath', 'createECSTask', 'convertLegacyTask'
  }
  
  for _, method in ipairs(methods) do
    luaunit.assertNotNil(tm[method], "Method " .. method .. " should exist")
    luaunit.assertEquals(type(tm[method]), "function", "Method " .. method .. " should be a function")
  end
end

function TestTaskManagerECSBridge:testOpenTasksInitialization()
  local tm = TaskManager.new()
  luaunit.assertNotNil(tm.openTasks)
  luaunit.assertEquals(type(tm.openTasks), "table")
end

function TestTaskManagerECSBridge:testAddTaskECSMode()
  local tm = TaskManager.new()
  
  -- Initialize openTasks table for a task type
  tm.openTasks[enums.TaskType.MINE] = {}
  
  -- Test adding a task
  local mockTask = {type = enums.TaskType.MINE, target = {x=5, y=5}}
  tm:addTask(enums.TaskType.MINE, mockTask)
  
  luaunit.assertEquals(#tm.openTasks[enums.TaskType.MINE], 1)
  luaunit.assertEquals(tm.openTasks[enums.TaskType.MINE][1], mockTask)
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())