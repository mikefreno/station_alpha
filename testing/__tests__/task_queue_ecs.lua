package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
Logger = require("logger")

-- Mock the required modules BEFORE requiring TaskQueue
local enums = require("game.utils.enums")
local Vec2 = require("game.utils.Vec2")

local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

-- Mock TaskAdapter (declare before require override)
MockTaskAdapter = {
  isTaskComponent = function(self, task)
    return task and task.componentType ~= nil
  end,
  
  canConvert = function(self, task)
    if not task then return false end
    if task.componentType then return true end -- Already an ECS component
    
    -- Check if legacy task can be converted
    local mapping = {
      [TaskType.MOVETO] = ComponentType.MOVEMENT_TASK,
      [TaskType.MINE] = ComponentType.MINING_TASK,
      [TaskType.CONSTRUCT] = ComponentType.CONSTRUCTION_TASK,
      [TaskType.CLEAN] = ComponentType.CLEANING_TASK
    }
    
    return mapping[task.type] ~= nil
  end,
  
  getTaskComponentType = function(self, task)
    if not task then return nil end
    
    if task.componentType then
      return task.componentType
    end
    
    -- Legacy task conversion mapping
    local mapping = {
      [TaskType.MOVETO] = ComponentType.MOVEMENT_TASK,
      [TaskType.MINE] = ComponentType.MINING_TASK,
      [TaskType.CONSTRUCT] = ComponentType.CONSTRUCTION_TASK,
      [TaskType.CLEAN] = ComponentType.CLEANING_TASK
    }
    
    return mapping[task.type]
  end,
  
  convertToECS = function(self, legacyTask, entityId)
    if not legacyTask or not legacyTask.type then return nil end
    
    local componentType = self:getTaskComponentType(legacyTask)
    if not componentType then return nil end
    
    -- Create a mock component based on type
    local component = {
      componentType = componentType,
      isComplete = false,
      priority = legacyTask.priority or 1.0,
      target = legacyTask.target
    }
    
    -- Add type-specific properties
    if componentType == ComponentType.MOVEMENT_TASK then
      component.requiredDistance = legacyTask.requiredDistance or 0.5
    elseif componentType == ComponentType.MINING_TASK then
      component.resourceType = legacyTask.resourceType or "stone"
    end
    
    return component, componentType
  end
}

-- Mock EntityManager and TaskComponentPool for testing
local MockEntityManager = {
  components = {},
  addComponent = function(self, entityId, componentType, component)
    if not self.components[componentType] then
      self.components[componentType] = {}
    end
    self.components[componentType][entityId] = component
  end,
  removeComponent = function(self, entityId, componentType)
    if self.components[componentType] then
      self.components[componentType][entityId] = nil
    end
  end,
  getComponent = function(self, entityId, componentType)
    if self.components[componentType] then
      return self.components[componentType][entityId]
    end
    return nil
  end
}

local MockTaskComponentPool = {
  released = {},
  acquired = {},
  
  acquire = function(self, componentType)
    if not self.acquired[componentType] then
      self.acquired[componentType] = {}
    end
    
    -- Create a new mock component
    local component = {
      componentType = componentType,
      isComplete = false,
      priority = 1.0
    }
    
    table.insert(self.acquired[componentType], component)
    return component
  end,
  
  release = function(self, componentType, component)
    if not self.released[componentType] then
      self.released[componentType] = {}
    end
    table.insert(self.released[componentType], component)
  end,
  
  wasReleased = function(self, componentType)
    return self.released[componentType] and #self.released[componentType] > 0
  end,
  
  clear = function(self)
    self.released = {}
    self.acquired = {}
  end
}

-- Mock require function to return our mocks - SET UP BEFORE REQUIRING TaskQueue
local originalRequire = require
function require(module)
  if module == "game.systems.EntityManager" then
    return MockEntityManager
  elseif module == "game.systems.TaskComponentPool" then
    return MockTaskComponentPool
  elseif module == "game.adapters.TaskAdapter" then
    return MockTaskAdapter
  else
    return originalRequire(module)
  end
end

-- NOW require TaskQueue after mocks are set up
local TaskQueue = require("game.components.TaskQueue")

-- Test class
TestTaskQueueECS = {}

function TestTaskQueueECS:setUp()
  -- Reset mocks
  MockEntityManager.components = {}
  MockTaskComponentPool:clear()
  
  -- Create a fresh TaskQueue for each test
  self.entityId = 1
  self.taskQueue = TaskQueue.new(self.entityId)
end

function TestTaskQueueECS:tearDown()
  if self.taskQueue then
    self.taskQueue:destroy()
  end
end

-- Test task pushing in ECS mode
function TestTaskQueueECS:test_pushTaskComponent()
  -- Create a mock task component
  local mockTaskComponent = {
    componentType = ComponentType.MOVEMENT_TASK,
    isComplete = false,
    target = Vec2.new(10, 10),
    priority = 1.0
  }
  
  self.taskQueue:push(mockTaskComponent)
  
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
  luaunit.assertTrue(self.taskQueue:hasActiveTasks())
end

function TestTaskQueueECS:test_pushLegacyTaskConversion()
  -- Create a legacy task
  local legacyTask = {
    type = TaskType.MOVETO,
    target = Vec2.new(5, 5),
    priority = 1.0,
    requiredDistance = 0.5
  }
  
  self.taskQueue:push(legacyTask)
  
  -- Should be converted and added
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
  luaunit.assertTrue(self.taskQueue:hasActiveTasks())
end

function TestTaskQueueECS:test_pushUnsupportedTask()
  -- Create an unsupported task
  local unsupportedTask = {
    type = "UNKNOWN_TYPE",
    data = "some data"
  }
  
  self.taskQueue:push(unsupportedTask)
  
  -- Should not be added
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 0)
  luaunit.assertFalse(self.taskQueue:hasActiveTasks())
end

-- Test task completion and cleanup
function TestTaskQueueECS:test_popCompletedTask()
  -- Create a completed task component
  local mockTaskComponent = {
    componentType = ComponentType.MOVEMENT_TASK,
    isComplete = true,
    target = Vec2.new(10, 10),
    priority = 1.0
  }
  
  self.taskQueue:push(mockTaskComponent)
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
  
  local poppedTask = self.taskQueue:pop()
  
  luaunit.assertNotNil(poppedTask)
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 0)
  luaunit.assertTrue(MockTaskComponentPool:wasReleased(ComponentType.MOVEMENT_TASK))
end

function TestTaskQueueECS:test_popNoCompletedTasks()
  -- Create an incomplete task component
  local mockTaskComponent = {
    componentType = ComponentType.MOVEMENT_TASK,
    isComplete = false,
    target = Vec2.new(10, 10),
    priority = 1.0
  }
  
  self.taskQueue:push(mockTaskComponent)
  
  local poppedTask = self.taskQueue:pop()
  
  luaunit.assertNil(poppedTask)
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
end

-- Test update method with task completion
function TestTaskQueueECS:test_updateCompletesTask()
  -- Create a task component that will complete
  local mockTaskComponent = {
    componentType = ComponentType.MOVEMENT_TASK,
    isComplete = false,
    target = Vec2.new(10, 10),
    priority = 1.0
  }
  
  self.taskQueue:push(mockTaskComponent)
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
  
  -- Simulate task completion
  mockTaskComponent.isComplete = true
  
  self.taskQueue:update(0.016)
  
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 0)
  luaunit.assertTrue(MockTaskComponentPool:wasReleased(ComponentType.MOVEMENT_TASK))
end

-- Test capacity limits
function TestTaskQueueECS:test_canAcceptNewTask()
  luaunit.assertTrue(self.taskQueue:canAcceptNewTask())
  
  -- Add a task to reach capacity (maxConcurrentTasks = 1)
  local mockTaskComponent = {
    componentType = ComponentType.MOVEMENT_TASK,
    isComplete = false,
    target = Vec2.new(10, 10),
    priority = 1.0
  }
  
  self.taskQueue:push(mockTaskComponent)
  
  luaunit.assertFalse(self.taskQueue:canAcceptNewTask())
end

function TestTaskQueueECS:test_pushWhenAtCapacity()
  -- Fill to capacity
  local mockTaskComponent1 = {
    componentType = ComponentType.MOVEMENT_TASK,
    isComplete = false,
    target = Vec2.new(10, 10),
    priority = 1.0
  }
  
  self.taskQueue:push(mockTaskComponent1)
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
  
  -- Try to add another task
  local mockTaskComponent2 = {
    componentType = ComponentType.MINING_TASK,
    isComplete = false,
    target = Vec2.new(5, 5),
    priority = 1.0
  }
  
  self.taskQueue:push(mockTaskComponent2)
  
  -- Should still be 1 (rejected the second task)
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
end

-- Test reset functionality
function TestTaskQueueECS:test_resetCleansUpTasks()
  -- Increase capacity to allow multiple tasks
  self.taskQueue.maxConcurrentTasks = 5
  
  -- Add multiple tasks of different types
  local taskTypes = {
    ComponentType.MOVEMENT_TASK,
    ComponentType.MINING_TASK,
    ComponentType.CONSTRUCTION_TASK
  }
  
  for i = 1, 3 do
    local mockTaskComponent = {
      componentType = taskTypes[i],
      isComplete = false,
      target = Vec2.new(i * 5, i * 5),
      priority = 1.0
    }
    self.taskQueue:push(mockTaskComponent)
  end
  
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 3)
  
  self.taskQueue:reset()
  
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 0)
  luaunit.assertTrue(MockTaskComponentPool:wasReleased(ComponentType.MOVEMENT_TASK))
end

-- Test destroy functionality
function TestTaskQueueECS:test_destroyCleansUpEverything()
  -- Add a task
  local mockTaskComponent = {
    componentType = ComponentType.MOVEMENT_TASK,
    isComplete = false,
    target = Vec2.new(10, 10),
    priority = 1.0
  }
  
  self.taskQueue:push(mockTaskComponent)
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
  
  self.taskQueue:destroy()
  
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 0)
  luaunit.assertTrue(MockTaskComponentPool:wasReleased(ComponentType.MOVEMENT_TASK))
end

-- Test addMovementTask convenience method
function TestTaskQueueECS:test_addMovementTask()
  local targetPosition = Vec2.new(15, 20)
  local success = self.taskQueue:addMovementTask(targetPosition)
  
  luaunit.assertTrue(success)
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 1)
  luaunit.assertTrue(self.taskQueue:hasActiveTasks())
end

-- Test legacy task conversion
function TestTaskQueueECS:test_legacyTaskConversion()
  -- Increase capacity to allow multiple tasks
  self.taskQueue.maxConcurrentTasks = 3
  
  -- Add legacy tasks
  local legacyTask1 = {
    type = TaskType.MOVETO,
    target = Vec2.new(5, 5),
    priority = 1.0,
    requiredDistance = 0.5
  }
  
  local legacyTask2 = {
    type = TaskType.MINE,
    target = Vec2.new(10, 10),
    priority = 2.0,
    requiredDistance = 1.0
  }
  
  self.taskQueue:push(legacyTask1)
  self.taskQueue:push(legacyTask2)
  
  -- Tasks should be converted automatically
  luaunit.assertEquals(self.taskQueue:getActiveTaskCount(), 2)
end

-- Test getTaskComponentType utility
function TestTaskQueueECS:test_getTaskComponentType()
  -- Test with ECS component
  local ecsComponent = {
    componentType = ComponentType.MINING_TASK
  }
  
  local componentType = self.taskQueue:getTaskComponentType(ecsComponent)
  luaunit.assertEquals(componentType, ComponentType.MINING_TASK)
  
  -- Test with legacy task
  local legacyTask = {
    type = TaskType.CONSTRUCT,
    target = Vec2.new(5, 5)
  }
  
  componentType = self.taskQueue:getTaskComponentType(legacyTask)
  luaunit.assertEquals(componentType, ComponentType.CONSTRUCTION_TASK)
  
  -- Test with nil
  componentType = self.taskQueue:getTaskComponentType(nil)
  luaunit.assertNil(componentType)
end

-- Run the tests
if not os.getenv("DISABLE_TESTS") then
  os.exit(luaunit.LuaUnit.run())
end

return TestTaskQueueECS