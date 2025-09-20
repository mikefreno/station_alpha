-- Test file for MiningProcessor
-- Tests mining logic, resource generation, and batch processing functionality

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

-- Mock Vec2 class
local MockVec2 = {}
MockVec2.__index = MockVec2

function MockVec2.new(x, y)
  return setmetatable({x = x or 0, y = y or 0}, MockVec2)
end

function MockVec2:__tostring()
  return string.format("Vec2(%s, %s)", self.x, self.y)
end

-- Mock component types
local MockComponentType = {
  MINING_TASK = "mining_task",
  HEALTH = "health",
  POSITION = "position",
  TOOL = "tool",
  SKILLS = "skills",
  INVENTORY = "inventory",
  MINEABLE = "mineable"
}

-- Mock EntityManager
local MockEntityManager = {
  components = {}
}

function MockEntityManager:getComponent(entityId, componentType)
  if not entityId or not componentType then
    return nil
  end
  local key = entityId .. "_" .. componentType
  return self.components[key]
end

function MockEntityManager:setComponent(entityId, componentType, component)
  if not entityId or not componentType then
    return
  end
  
  -- Add markComplete method to mining tasks
  if componentType == MockComponentType.MINING_TASK and component and not component.markComplete then
    function component:markComplete()
      self.isComplete = true
    end
  end
  
  local key = entityId .. "_" .. componentType
  self.components[key] = component
end

function MockEntityManager:addComponent(entityId, componentType, component)
  self:setComponent(entityId, componentType, component)
end

function MockEntityManager:hasComponent(entityId, componentType)
  local key = entityId .. "_" .. componentType
  return self.components[key] ~= nil
end

function MockEntityManager:removeComponent(entityId, componentType)
  local key = entityId .. "_" .. componentType
  self.components[key] = nil
end

function MockEntityManager:clear()
  self.components = {}
end

-- Mock TaskComponentPool
local MockTaskComponentPool = {
  returnComponent = function(self, component) end
}

-- Mock MapManager  
local MockMapManager = {
  getTileAt = function(self, position)
    return {
      material = "stone",
      hardness = 5,
      resourceType = "stone",
      resourceAmount = 10
    }
  end,
  
  setTileAt = function(self, position, tile) end,
  
  generateResourceEntity = function(self, position, resourceType, amount)
    return 9999 -- Mock resource entity ID
  end
}

-- Set up global mocks
_G.Logger = MockLogger
_G.Vec2 = MockVec2
_G.EntityManager = MockEntityManager
_G.TaskComponentPool = MockTaskComponentPool
_G.MapManager = MockMapManager

-- Load component enums and MiningProcessor
local enums = require("game.utils.enums")
enums.ComponentType = MockComponentType

local MiningProcessor = require("game.systems.MiningProcessor")

-- Test suite
TestMiningProcessor = {}

function TestMiningProcessor:setUp()
  MockEntityManager:clear()
  self.processor = MiningProcessor.new()
end

function TestMiningProcessor:tearDown()
  MockEntityManager:clear()
end

-- Test: Basic processor creation
function TestMiningProcessor:testProcessorCreation()
  luaunit.assertNotNil(self.processor)
  luaunit.assertEquals(self.processor.defaultSwingDuration, 1.0)
  luaunit.assertEquals(self.processor.defaultSwingsPerResource, 5)
  luaunit.assertEquals(self.processor.processedEntities, 0)
  luaunit.assertEquals(self.processor.completedTasks, 0)
  luaunit.assertEquals(self.processor.resourcesGenerated, 0)
end

-- Test: Process empty batch
function TestMiningProcessor:testProcessEmptyBatch()
  self.processor:processBatch({}, 0.1)
  luaunit.assertEquals(self.processor.processedEntities, 0)
  luaunit.assertEquals(self.processor.completedTasks, 0)
end

-- Test: Process nil batch
function TestMiningProcessor:testProcessNilBatch()
  self.processor:processBatch(nil, 0.1)
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Single entity mining processing
function TestMiningProcessor:testSingleEntityMining()
  local entityId = 100
  local targetId = 200
  
  -- Set up mining task
  local miningTask = {
    target = targetId,
    swingTimer = 0.0,
    totalSwings = 0,
    isComplete = false,
    resourcesExtracted = 0
  }
  MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
  
  -- Set up target health
  local targetHealth = {
    current = 100,
    maximum = 100
  }
  MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
  
  -- Set up target as mineable
  local mineable = {
    hardness = 1.0,
    resourceType = "stone"
  }
  MockEntityManager:setComponent(targetId, MockComponentType.MINEABLE, mineable)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Process one frame
  self.processor:processBatch({entityId}, 0.5)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  luaunit.assertEquals(miningTask.swingTimer, 0.5)
  luaunit.assertEquals(miningTask.totalSwings, 0) -- No swing completed yet
end

-- Test: Complete mining swing
function TestMiningProcessor:testCompleteMiningSwing()
  local entityId = 100
  local targetId = 200
  
  -- Set up mining task with almost complete swing
  local miningTask = {
    target = targetId,
    swingTimer = 0.8,
    totalSwings = 0,
    isComplete = false,
    resourcesExtracted = 0
  }
  MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
  
  -- Set up target health
  local targetHealth = {
    current = 100,
    maximum = 100
  }
  MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Process enough time to complete swing
  self.processor:processBatch({entityId}, 0.3)
  
  luaunit.assertEquals(miningTask.totalSwings, 1)
  luaunit.assertEquals(miningTask.swingTimer, 0.1) -- Timer reset with remainder
  luaunit.assertTrue(targetHealth.current < 100) -- Target took damage
end

-- Test: Mining with tool bonus
function TestMiningProcessor:testMiningWithToolBonus()
  local entityId = 100
  local targetId = 200
  
  -- Set up mining task
  local miningTask = {
    target = targetId,
    swingTimer = 0.8,
    totalSwings = 0,
    isComplete = false,
    resourcesExtracted = 0
  }
  MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
  
  -- Set up target health
  local targetHealth = {
    current = 100,
    maximum = 100
  }
  MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up tool with mining bonus
  local tool = {
    toolType = "pickaxe",
    miningBonus = 2.0,
    durability = 100
  }
  MockEntityManager:setComponent(entityId, MockComponentType.TOOL, tool)
  
  -- Process swing completion
  self.processor:processBatch({entityId}, 0.3)
  
  luaunit.assertEquals(miningTask.totalSwings, 1)
  -- With tool bonus, should deal more damage
  luaunit.assertTrue(targetHealth.current < 80) -- More damage than base
end

-- Test: Mining with skills bonus
function TestMiningProcessor:testMiningWithSkillsBonus()
  local entityId = 100
  local targetId = 200
  
  -- Set up mining task
  local miningTask = {
    target = targetId,
    swingTimer = 0.8,
    totalSwings = 0,
    isComplete = false,
    resourcesExtracted = 0
  }
  MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
  
  -- Set up target health
  local targetHealth = {
    current = 100,
    maximum = 100
  }
  MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up skills with mining bonus
  local skills = {
    mining = 80 -- High mining skill
  }
  MockEntityManager:setComponent(entityId, MockComponentType.SKILLS, skills)
  
  -- Process swing completion
  self.processor:processBatch({entityId}, 0.3)
  
  luaunit.assertEquals(miningTask.totalSwings, 1)
  luaunit.assertTrue(targetHealth.current < 100) -- Damage dealt
end

-- Test: Resource generation on target destruction
function TestMiningProcessor:testResourceGeneration()
  local entityId = 100
  local targetId = 200
  
  -- Set up mining task with high swing count
  local miningTask = {
    target = targetId,
    swingTimer = 0.0,
    totalSwings = 4, -- Almost at required swings
    isComplete = false,
    resourcesExtracted = 0
  }
  MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
  
  -- Set up target health (low health)
  local targetHealth = {
    current = 10,
    maximum = 100
  }
  MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Process enough to complete mining
  self.processor:processBatch({entityId}, 1.1)
  
  luaunit.assertEquals(miningTask.totalSwings, 5)
  luaunit.assertTrue(targetHealth.current <= 0) -- Target destroyed
  luaunit.assertTrue(miningTask.resourcesExtracted > 0) -- Resources generated
  luaunit.assertTrue(self.processor.resourcesGenerated > 0)
end

-- Test: Task completion
function TestMiningProcessor:testTaskCompletion()
  local entityId = 100
  local targetId = 200
  
  -- Set up mining task
  local miningTask = {
    target = targetId,
    swingTimer = 0.0,
    totalSwings = 4,
    isComplete = false,
    resourcesExtracted = 0
  }
  MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
  
  -- Set up target health (very low)
  local targetHealth = {
    current = 1,
    maximum = 100
  }
  MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Process to complete task
  self.processor:processBatch({entityId}, 1.1)
  
  luaunit.assertTrue(miningTask.isComplete)
  luaunit.assertEquals(self.processor.completedTasks, 1)
end

-- Test: Batch processing multiple entities
function TestMiningProcessor:testBatchProcessing()
  local entities = {101, 102, 103}
  
  for i, entityId in ipairs(entities) do
    local targetId = 200 + i
    
    -- Set up mining task
    local miningTask = {
      target = targetId,
      swingTimer = 0.0,
      totalSwings = 0,
      isComplete = false,
      resourcesExtracted = 0
    }
    MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
    
    -- Set up target health
    local targetHealth = {
      current = 100,
      maximum = 100
    }
    MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
    
    -- Set up entity position
    local position = MockVec2.new(10 + i, 10 + i)
    MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  end
  
  -- Process batch
  self.processor:processBatch(entities, 0.5)
  
  luaunit.assertEquals(self.processor.processedEntities, 3)
  
  -- Verify all entities were processed
  for i, entityId in ipairs(entities) do
    local miningTask = MockEntityManager:getComponent(entityId, MockComponentType.MINING_TASK)
    luaunit.assertEquals(miningTask.swingTimer, 0.5)
  end
end

-- Test: Invalid entity handling
function TestMiningProcessor:testInvalidEntityHandling()
  local entityId = 100
  
  -- Entity without mining task should be skipped
  self.processor:processBatch({entityId}, 0.1)
  
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Already completed task handling
function TestMiningProcessor:testCompletedTaskHandling()
  local entityId = 100
  local targetId = 200
  
  -- Set up completed mining task
  local miningTask = {
    target = targetId,
    swingTimer = 0.0,
    totalSwings = 5,
    isComplete = true,
    resourcesExtracted = 10
  }
  MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
  
  -- Process batch - should skip completed task
  self.processor:processBatch({entityId}, 0.1)
  
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Performance with large batch
function TestMiningProcessor:testLargeBatchPerformance()
  local entities = {}
  local batchSize = 50
  
  -- Create large batch of mining entities
  for i = 1, batchSize do
    local entityId = 1000 + i
    local targetId = 2000 + i
    table.insert(entities, entityId)
    
    -- Set up mining task
    local miningTask = {
      target = targetId,
      swingTimer = 0.0,
      totalSwings = 0,
      isComplete = false,
      resourcesExtracted = 0
    }
    MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
    
    -- Set up target health
    local targetHealth = {
      current = 100,
      maximum = 100
    }
    MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
    
    -- Set up entity position
    local position = MockVec2.new(i, i)
    MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  end
  
  -- Process large batch
  local startTime = love.timer.getTime()
  self.processor:processBatch(entities, 0.016) -- 60 FPS frame time
  local endTime = love.timer.getTime()
  local processingTime = endTime - startTime
  
  luaunit.assertEquals(self.processor.processedEntities, batchSize)
  luaunit.assertTrue(processingTime < 0.01) -- Should complete within 10ms
end

-- Test: Statistics tracking
function TestMiningProcessor:testStatisticsTracking()
  local entityId = 100
  local targetId = 200
  
  -- Set up mining task for completion
  local miningTask = {
    target = targetId,
    swingTimer = 0.8,
    totalSwings = 4,
    isComplete = false,
    resourcesExtracted = 0
  }
  MockEntityManager:setComponent(entityId, MockComponentType.MINING_TASK, miningTask)
  
  -- Set up target health (low)
  local targetHealth = {
    current = 5,
    maximum = 100
  }
  MockEntityManager:setComponent(targetId, MockComponentType.HEALTH, targetHealth)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Process to generate stats
  self.processor:processBatch({entityId}, 1.1)
  
  local stats = self.processor:getStats()
  luaunit.assertNotNil(stats)
  luaunit.assertEquals(stats.processedEntities, 1)
  luaunit.assertEquals(stats.completedTasks, 1)
  luaunit.assertTrue(stats.resourcesGenerated > 0)
end

-- Run the tests
luaunit.LuaUnit.run()