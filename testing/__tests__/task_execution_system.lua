-- Test file for TaskExecutionSystem
-- Tests the core coordination and lifecycle management functionality

package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
require("testing.loveStub")

-- Mock the logger to avoid output during tests
local MockLogger = {
  info = function(self, msg) end,
  debug = function(self, msg) end,
  warn = function(self, msg) end,
  error = function(self, msg) end
}

-- Mock component types
local MockComponentType = {
  MOVEMENT_TASK = 1,
  MINING_TASK = 2,
  CONSTRUCTION_TASK = 3,
  CLEANING_TASK = 4
}

-- Mock enums module
package.loaded["utils.enums"] = {
  ComponentType = MockComponentType
}

-- Mock logger module
package.loaded["logger"] = MockLogger

-- Mock EntityManager for testing
local MockEntityManager = {
  query = function(self, componentType)
    return self._entities[componentType] or {}
  end,
  addComponent = function(self, entityId, componentType, component)
    if not self._components[componentType] then
      self._components[componentType] = {}
    end
    self._components[componentType][entityId] = component
  end,
  removeComponent = function(self, entityId, componentType)
    if self._components[componentType] then
      self._components[componentType][entityId] = nil
    end
  end,
  getComponent = function(self, entityId, componentType)
    if self._components[componentType] then
      return self._components[componentType][entityId]
    end
    return nil
  end,
  _entities = {},
  _components = {},
  reset = function(self)
    self._entities = {}
    self._components = {}
  end
}

-- Mock TaskComponentPool
local MockTaskComponentPool = {
  release = function(self, componentType, component)
    -- Mock implementation
  end
}

-- Override require for system modules
package.loaded["systems.EntityManager"] = MockEntityManager
package.loaded["systems.TaskComponentPool"] = MockTaskComponentPool

local TaskExecutionSystem = require("game.systems.TaskExecutionSystem")

TestTaskExecutionSystem = {}

function TestTaskExecutionSystem:setUp()
  -- Reset the system state
  TaskExecutionSystem.isInitialized = false
  TaskExecutionSystem.processors = {}
  TaskExecutionSystem.dependencyResolver = nil
  TaskExecutionSystem.processingOrder = {}
  TaskExecutionSystem.statistics = {
    frametime = 0,
    tasksProcessed = 0,
    taskCounts = {},
    processingTimes = {}
  }
  
  MockEntityManager:reset()
end

function TestTaskExecutionSystem:testInitialization()
  luaunit.assertFalse(TaskExecutionSystem.isInitialized)
  
  TaskExecutionSystem:init()
  
  luaunit.assertTrue(TaskExecutionSystem.isInitialized)
  luaunit.assertEquals(#TaskExecutionSystem.processingOrder, 4)
  luaunit.assertEquals(TaskExecutionSystem.processingOrder[1], MockComponentType.MOVEMENT_TASK)
  luaunit.assertEquals(TaskExecutionSystem.processingOrder[2], MockComponentType.MINING_TASK)
  luaunit.assertEquals(TaskExecutionSystem.processingOrder[3], MockComponentType.CONSTRUCTION_TASK)
  luaunit.assertEquals(TaskExecutionSystem.processingOrder[4], MockComponentType.CLEANING_TASK)
end

function TestTaskExecutionSystem:testDoubleInitialization()
  TaskExecutionSystem:init()
  luaunit.assertTrue(TaskExecutionSystem.isInitialized)
  
  -- Second init should not break anything
  TaskExecutionSystem:init()
  luaunit.assertTrue(TaskExecutionSystem.isInitialized)
end

function TestTaskExecutionSystem:testRegisterProcessor()
  TaskExecutionSystem:init()
  
  local mockProcessor = {
    process = function(self, entityId, component, dt)
      return true
    end
  }
  
  local result = TaskExecutionSystem:registerProcessor(MockComponentType.MOVEMENT_TASK, mockProcessor)
  luaunit.assertTrue(result)
  luaunit.assertEquals(TaskExecutionSystem.processors[MockComponentType.MOVEMENT_TASK], mockProcessor)
end

function TestTaskExecutionSystem:testRegisterProcessorInvalidProcessor()
  TaskExecutionSystem:init()
  
  local invalidProcessor = {} -- Missing process method
  
  local result = TaskExecutionSystem:registerProcessor(MockComponentType.MOVEMENT_TASK, invalidProcessor)
  luaunit.assertFalse(result)
  luaunit.assertNil(TaskExecutionSystem.processors[MockComponentType.MOVEMENT_TASK])
end

function TestTaskExecutionSystem:testRegisterProcessorNotInitialized()
  local mockProcessor = {
    process = function(self, entityId, component, dt) end
  }
  
  local result = TaskExecutionSystem:registerProcessor(MockComponentType.MOVEMENT_TASK, mockProcessor)
  luaunit.assertFalse(result)
end

function TestTaskExecutionSystem:testSetDependencyResolver()
  TaskExecutionSystem:init()
  
  local mockResolver = {
    resolveDependencies = function(self) end
  }
  
  local result = TaskExecutionSystem:setDependencyResolver(mockResolver)
  luaunit.assertTrue(result)
  luaunit.assertEquals(TaskExecutionSystem.dependencyResolver, mockResolver)
end

function TestTaskExecutionSystem:testSetInvalidDependencyResolver()
  TaskExecutionSystem:init()
  
  local result = TaskExecutionSystem:setDependencyResolver(nil)
  luaunit.assertFalse(result)
  luaunit.assertNil(TaskExecutionSystem.dependencyResolver)
end

function TestTaskExecutionSystem:testAssignTask()
  TaskExecutionSystem:init()
  
  local mockComponent = {
    getComponentType = function(self)
      return MockComponentType.MOVEMENT_TASK
    end,
    setPriority = function(self, priority)
      self.priority = priority
    end,
    priority = 0
  }
  
  local result = TaskExecutionSystem:assignTask(1, mockComponent, 5)
  luaunit.assertTrue(result)
  luaunit.assertEquals(mockComponent.priority, 5)
  
  local storedComponent = MockEntityManager:getComponent(1, MockComponentType.MOVEMENT_TASK)
  luaunit.assertEquals(storedComponent, mockComponent)
end

function TestTaskExecutionSystem:testAssignTaskInvalidParameters()
  TaskExecutionSystem:init()
  
  local result1 = TaskExecutionSystem:assignTask(nil, {})
  luaunit.assertFalse(result1)
  
  local result2 = TaskExecutionSystem:assignTask(1, nil)
  luaunit.assertFalse(result2)
end

function TestTaskExecutionSystem:testProcessTaskType()
  TaskExecutionSystem:init()
  
  local processCount = 0
  local mockProcessor = {
    process = function(self, entityId, component, dt)
      processCount = processCount + 1
      return true
    end
  }
  
  local mockComponent = {
    getComponentType = function(self)
      return MockComponentType.MOVEMENT_TASK
    end
  }
  
  -- Set up mock data
  MockEntityManager._entities[MockComponentType.MOVEMENT_TASK] = {1, 2}
  MockEntityManager._components[MockComponentType.MOVEMENT_TASK] = {
    [1] = mockComponent,
    [2] = mockComponent
  }
  
  local processed = TaskExecutionSystem:processTaskType(MockComponentType.MOVEMENT_TASK, mockProcessor, 0.016)
  
  luaunit.assertEquals(processed, 2)
  luaunit.assertEquals(processCount, 2)
end

function TestTaskExecutionSystem:testProcessTaskTypeNoEntities()
  TaskExecutionSystem:init()
  
  local mockProcessor = {
    process = function(self, entityId, component, dt)
      return true
    end
  }
  
  -- No entities with this component
  MockEntityManager._entities[MockComponentType.MOVEMENT_TASK] = {}
  
  local processed = TaskExecutionSystem:processTaskType(MockComponentType.MOVEMENT_TASK, mockProcessor, 0.016)
  luaunit.assertEquals(processed, 0)
end

function TestTaskExecutionSystem:testRemoveCompletedTasks()
  TaskExecutionSystem:init()
  
  local completedComponent = {
    isComplete = function(self)
      return true
    end
  }
  
  local incompleteComponent = {
    isComplete = function(self)
      return false
    end
  }
  
  -- Set up test data
  MockEntityManager._entities[MockComponentType.MOVEMENT_TASK] = {1, 2}
  MockEntityManager._components[MockComponentType.MOVEMENT_TASK] = {
    [1] = completedComponent,
    [2] = incompleteComponent
  }
  
  TaskExecutionSystem:removeCompletedTasks()
  
  -- Check that completed task was removed
  luaunit.assertNil(MockEntityManager._components[MockComponentType.MOVEMENT_TASK][1])
  -- Check that incomplete task remains
  luaunit.assertEquals(MockEntityManager._components[MockComponentType.MOVEMENT_TASK][2], incompleteComponent)
end

function TestTaskExecutionSystem:testUpdateWithoutProcessors()
  TaskExecutionSystem:init()
  
  -- Should not crash with no processors
  TaskExecutionSystem:update(0.016)
  
  luaunit.assertTrue(TaskExecutionSystem.statistics.frametime >= 0)
  luaunit.assertEquals(TaskExecutionSystem.statistics.tasksProcessed, 0)
end

function TestTaskExecutionSystem:testUpdateWithDependencyResolver()
  TaskExecutionSystem:init()
  
  local resolverCalled = false
  local mockResolver = {
    resolveDependencies = function(self)
      resolverCalled = true
    end
  }
  
  TaskExecutionSystem:setDependencyResolver(mockResolver)
  TaskExecutionSystem:update(0.016)
  
  luaunit.assertTrue(resolverCalled)
end

function TestTaskExecutionSystem:testStatistics()
  TaskExecutionSystem:init()
  
  local stats = TaskExecutionSystem:getStatistics()
  
  luaunit.assertNotNil(stats.frametime)
  luaunit.assertNotNil(stats.tasksProcessed)
  luaunit.assertNotNil(stats.taskCounts)
  luaunit.assertNotNil(stats.processingTimes)
  luaunit.assertNotNil(stats.averageTaskTime)
end

function TestTaskExecutionSystem:testResetStatistics()
  TaskExecutionSystem:init()
  
  TaskExecutionSystem.statistics.frametime = 1.0
  TaskExecutionSystem.statistics.tasksProcessed = 10
  TaskExecutionSystem.statistics.taskCounts[MockComponentType.MOVEMENT_TASK] = 5
  TaskExecutionSystem.statistics.processingTimes[MockComponentType.MOVEMENT_TASK] = 0.5
  
  TaskExecutionSystem:resetStatistics()
  
  luaunit.assertEquals(TaskExecutionSystem.statistics.frametime, 0)
  luaunit.assertEquals(TaskExecutionSystem.statistics.tasksProcessed, 0)
  luaunit.assertEquals(TaskExecutionSystem.statistics.taskCounts[MockComponentType.MOVEMENT_TASK], 0)
  luaunit.assertEquals(TaskExecutionSystem.statistics.processingTimes[MockComponentType.MOVEMENT_TASK], 0)
end

function TestTaskExecutionSystem:testProcessorCount()
  TaskExecutionSystem:init()
  
  luaunit.assertEquals(TaskExecutionSystem:getProcessorCount(), 0)
  
  local mockProcessor = {
    process = function(self, entityId, component, dt) end
  }
  
  TaskExecutionSystem:registerProcessor(MockComponentType.MOVEMENT_TASK, mockProcessor)
  luaunit.assertEquals(TaskExecutionSystem:getProcessorCount(), 1)
  
  TaskExecutionSystem:registerProcessor(MockComponentType.MINING_TASK, mockProcessor)
  luaunit.assertEquals(TaskExecutionSystem:getProcessorCount(), 2)
end

function TestTaskExecutionSystem:testHasProcessor()
  TaskExecutionSystem:init()
  
  luaunit.assertFalse(TaskExecutionSystem:hasProcessor(MockComponentType.MOVEMENT_TASK))
  
  local mockProcessor = {
    process = function(self, entityId, component, dt) end
  }
  
  TaskExecutionSystem:registerProcessor(MockComponentType.MOVEMENT_TASK, mockProcessor)
  luaunit.assertTrue(TaskExecutionSystem:hasProcessor(MockComponentType.MOVEMENT_TASK))
  luaunit.assertFalse(TaskExecutionSystem:hasProcessor(MockComponentType.MINING_TASK))
end

-- Run tests if this file is executed directly
if arg and arg[0] == "testing/__tests__/task_execution_system.lua" then
  os.exit(luaunit.LuaUnit.run())
end

return TestTaskExecutionSystem