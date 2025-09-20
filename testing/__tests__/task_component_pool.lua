local luaunit = require("luaunit")

-- Import love stub for timer functions
require("loveStub")

-- Import Logger stub
local Logger = {
  debug = function(msg) end,
  info = function(msg) end,
  warn = function(msg) end,
  error = function(msg) print("ERROR: " .. msg) end
}
_G.Logger = Logger

-- Import components and systems
local TaskComponentPool = require("game.systems.TaskComponentPool")
local ComponentType = require("game.utils.enums").ComponentType
local ToolType = require("game.utils.enums").ToolType
local ResourceType = require("game.utils.enums").ResourceType

-- Mock EntityManager for testing
local EntityManager = {
  getComponent = function(entityId, componentType)
    return { x = 5, y = 5 }
  end
}
_G.EntityManager = EntityManager

-- Test TaskComponentPool
local TestTaskComponentPool = {}

function TestTaskComponentPool:setUp()
  -- Reset pool state before each test
  TaskComponentPool.pools = {
    [ComponentType.MOVEMENT_TASK] = {},
    [ComponentType.MINING_TASK] = {},
    [ComponentType.CONSTRUCTION_TASK] = {},
    [ComponentType.CLEANING_TASK] = {}
  }
  TaskComponentPool.poolSizes = {
    [ComponentType.MOVEMENT_TASK] = 0,
    [ComponentType.MINING_TASK] = 0,
    [ComponentType.CONSTRUCTION_TASK] = 0,
    [ComponentType.CLEANING_TASK] = 0
  }
  TaskComponentPool.poolStats = {
    [ComponentType.MOVEMENT_TASK] = { acquired = 0, released = 0, created = 0, reused = 0 },
    [ComponentType.MINING_TASK] = { acquired = 0, released = 0, created = 0, reused = 0 },
    [ComponentType.CONSTRUCTION_TASK] = { acquired = 0, released = 0, created = 0, reused = 0 },
    [ComponentType.CLEANING_TASK] = { acquired = 0, released = 0, created = 0, reused = 0 }
  }
  TaskComponentPool:init(0)
end

function TestTaskComponentPool:testInitialization()
  luaunit.assertNotNil(TaskComponentPool.pools)
  luaunit.assertNotNil(TaskComponentPool.poolSizes)
  luaunit.assertNotNil(TaskComponentPool.poolStats)
  luaunit.assertEquals(TaskComponentPool.poolSizes[ComponentType.MOVEMENT_TASK], 10)
  luaunit.assertEquals(TaskComponentPool.poolSizes[ComponentType.MINING_TASK], 10)
end

function TestTaskComponentPool:testAcquireComponent()
  local component = TaskComponentPool:acquire(ComponentType.MOVEMENT_TASK)
  luaunit.assertNotNil(component)
  luaunit.assertTrue(component._poolable)
  luaunit.assertEquals(TaskComponentPool.poolSizes[ComponentType.MOVEMENT_TASK], 9)
  luaunit.assertEquals(TaskComponentPool.poolStats[ComponentType.MOVEMENT_TASK].acquired, 1)
  luaunit.assertEquals(TaskComponentPool.poolStats[ComponentType.MOVEMENT_TASK].reused, 1)
end

function TestTaskComponentPool:testAcquireCreatesNew()
  -- Empty the pool first
  local components = {}
  for i = 1, 10 do
    components[i] = TaskComponentPool:acquire(ComponentType.MINING_TASK)
  end
  luaunit.assertEquals(TaskComponentPool.poolSizes[ComponentType.MINING_TASK], 0)

  -- Next acquire should create new component
  local newComponent = TaskComponentPool:acquire(ComponentType.MINING_TASK)
  luaunit.assertNotNil(newComponent)
  luaunit.assertEquals(TaskComponentPool.poolStats[ComponentType.MINING_TASK].created, 1)
end

function TestTaskComponentPool:testReleaseComponent()
  local component = TaskComponentPool:acquire(ComponentType.CONSTRUCTION_TASK)
  luaunit.assertNotNil(component)

  TaskComponentPool:release(component, ComponentType.CONSTRUCTION_TASK)
  luaunit.assertEquals(TaskComponentPool.poolSizes[ComponentType.CONSTRUCTION_TASK], 10)
  luaunit.assertEquals(TaskComponentPool.poolStats[ComponentType.CONSTRUCTION_TASK].released, 1)
end

function TestTaskComponentPool:testComponentReset()
  local MovementTask = require("game.components.MovementTask")
  local component = MovementTask:new({ x = 10, y = 10 })
  luaunit.assertNotNil(component)

  -- Set some state
  component.currentWaypoint = 5
  component.movementSpeed = 2.0

  -- Reset should clear state
  component:reset()
  luaunit.assertEquals(component.currentWaypoint, 1)
  luaunit.assertEquals(component.movementSpeed, 1.0)
  luaunit.assertNil(component.targetPosition)
end

function TestTaskComponentPool:testPreAllocate()
  TaskComponentPool:preAllocate(ComponentType.CLEANING_TASK, 5)
  luaunit.assertEquals(TaskComponentPool.poolSizes[ComponentType.CLEANING_TASK], 15) -- 10 initial + 5 more
end

function TestTaskComponentPool:testPoolSizeLimit()
  -- Fill pool to max capacity
  local components = {}
  for i = 1, 150 do -- Try to exceed max size of 100
    local component = TaskComponentPool:acquire(ComponentType.MOVEMENT_TASK)
    components[i] = component
  end

  -- Release all back to pool
  for _, component in ipairs(components) do
    TaskComponentPool:release(component, ComponentType.MOVEMENT_TASK)
  end

  -- Pool should not exceed max size
  luaunit.assertTrue(TaskComponentPool.poolSizes[ComponentType.MOVEMENT_TASK] <= 100)
end

function TestTaskComponentPool:testCleanup()
  -- Fill pool with many components
  for i = 1, 60 do
    local component = TaskComponentPool:acquire(ComponentType.MINING_TASK)
    TaskComponentPool:release(component, ComponentType.MINING_TASK)
  end

  local initialSize = TaskComponentPool.poolSizes[ComponentType.MINING_TASK]
  luaunit.assertTrue(initialSize > 50)

  -- Trigger cleanup
  TaskComponentPool:cleanup(61.0) -- Past cleanup interval

  local newSize = TaskComponentPool.poolSizes[ComponentType.MINING_TASK]
  luaunit.assertTrue(newSize < initialSize)
end

function TestTaskComponentPool:testPoolStats()
  -- Generate some activity
  local component1 = TaskComponentPool:acquire(ComponentType.CLEANING_TASK)
  local component2 = TaskComponentPool:acquire(ComponentType.CLEANING_TASK)
  TaskComponentPool:release(component1, ComponentType.CLEANING_TASK)

  local totalStats, poolStats = TaskComponentPool:getPoolStats()
  luaunit.assertNotNil(totalStats)
  luaunit.assertNotNil(poolStats)
  luaunit.assertEquals(totalStats.totalAcquired, 2)
  luaunit.assertEquals(totalStats.totalReleased, 1)
  luaunit.assertTrue(totalStats.reuseRates[ComponentType.CLEANING_TASK] > 0)
end

function TestTaskComponentPool:testFactoryMethods()
  local MovementTask = require("game.components.MovementTask")
  local MiningTask = require("game.components.MiningTask")
  local ConstructionTask = require("game.components.ConstructionTask")
  local CleaningTask = require("game.components.CleaningTask")

  -- Test MovementTask factory
  local movementTask = MovementTask.newFromPool({ x = 5, y = 5 })
  luaunit.assertNotNil(movementTask)
  luaunit.assertEquals(movementTask.targetPosition.x, 5)
  luaunit.assertEquals(movementTask.targetPosition.y, 5)

  -- Test MiningTask factory
  local miningTask = MiningTask.newFromPool(123, 5, ToolType.PICKAXE, ResourceType.STONE)
  luaunit.assertNotNil(miningTask)
  luaunit.assertEquals(miningTask.target, 123)
  luaunit.assertEquals(miningTask.swingsRequired, 5)
  luaunit.assertEquals(miningTask.toolRequired, ToolType.PICKAXE)

  -- Test ConstructionTask factory
  local materials = { [ResourceType.WOOD] = 5, [ResourceType.STONE] = 3 }
  local constructionTask = ConstructionTask.newFromPool(456, 789, materials)
  luaunit.assertNotNil(constructionTask)
  luaunit.assertEquals(constructionTask.target, 456)
  luaunit.assertEquals(constructionTask.blueprintEntity, 789)

  -- Test CleaningTask factory
  local cleaningTask = CleaningTask.newFromPool({ x = 10, y = 10 }, 3.0, ToolType.BROOM)
  luaunit.assertNotNil(cleaningTask)
  luaunit.assertEquals(cleaningTask.cleaningRadius, 3.0)
  luaunit.assertEquals(cleaningTask.cleaningTool, ToolType.BROOM)
end

function TestTaskComponentPool:testComponentReuse()
  -- Create and release a component
  local component1 = TaskComponentPool:acquire(ComponentType.MOVEMENT_TASK)
  local originalId = tostring(component1)
  TaskComponentPool:release(component1, ComponentType.MOVEMENT_TASK)

  -- Acquire again - should get the same component back
  local component2 = TaskComponentPool:acquire(ComponentType.MOVEMENT_TASK)
  local reusedId = tostring(component2)
  
  luaunit.assertEquals(originalId, reusedId)
  luaunit.assertEquals(TaskComponentPool.poolStats[ComponentType.MOVEMENT_TASK].reused, 2)
end

function TestTaskComponentPool:testInvalidComponentType()
  local component = TaskComponentPool:acquire(999) -- Invalid type
  luaunit.assertNil(component)
  
  TaskComponentPool:release(component, 999) -- Should not crash
end

function TestTaskComponentPool:testIsSupported()
  luaunit.assertTrue(TaskComponentPool:isSupported(ComponentType.MOVEMENT_TASK))
  luaunit.assertTrue(TaskComponentPool:isSupported(ComponentType.MINING_TASK))
  luaunit.assertFalse(TaskComponentPool:isSupported(999))
end

-- Run tests
os.exit(luaunit.LuaUnit.run())