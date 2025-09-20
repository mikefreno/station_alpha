-- Test file for CleaningProcessor
-- Tests area cleaning logic, dirt removal, and batch processing functionality

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
  CLEANING_TASK = "cleaning_task",
  POSITION = "position",
  TOOL = "tool",
  SKILLS = "skills",
  DIRT = "dirt"
}

-- Mock EntityManager
local MockEntityManager = {
  components = {},
  entities = {}, -- Track all entities
  dirtEntities = {} -- Track dirt entities for testing
}

function MockEntityManager:getComponent(entityId, componentType)
  local key = entityId .. "_" .. componentType
  return self.components[key]
end

function MockEntityManager:setComponent(entityId, componentType, component)
  if not entityId or not componentType then
    return
  end
  
  -- Track entity existence
  if not self.entities[entityId] then
    self.entities[entityId] = true
  end
  
  -- Add markComplete method to cleaning tasks
  if componentType == MockComponentType.CLEANING_TASK and component and not component.markComplete then
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

function MockEntityManager:removeEntity(entityId)
  -- Remove all components for this entity
  for key, _ in pairs(self.components) do
    if key:match("^" .. entityId .. "_") then
      self.components[key] = nil
    end
  end
  
  -- Remove from dirt entities tracking
  for i, id in ipairs(self.dirtEntities) do
    if id == entityId then
      table.remove(self.dirtEntities, i)
      break
    end
  end
end

function MockEntityManager:clear()
  self.components = {}
  self.entities = {}
  self.dirtEntities = {}
end

-- Mock getEntitiesWithinRadius for testing
function MockEntityManager:getEntitiesWithinRadius(center, radius, componentFilter)
  local entitiesInRadius = {}
  
  for _, entityId in ipairs(self.dirtEntities) do
    if componentFilter and componentFilter == MockComponentType.DIRT then
      local position = self:getComponent(entityId, MockComponentType.POSITION)
      if position then
        local distance = math.sqrt((position.x - center.x)^2 + (position.y - center.y)^2)
        if distance <= radius then
          table.insert(entitiesInRadius, entityId)
        end
      end
    end
  end
  
  return entitiesInRadius
end

-- Mock TaskComponentPool
local MockTaskComponentPool = {
  returnComponent = function(self, component) end
}

-- Set up global mocks
_G.Logger = MockLogger
_G.Vec2 = MockVec2
_G.EntityManager = MockEntityManager
_G.TaskComponentPool = MockTaskComponentPool

-- Load component enums and CleaningProcessor
local enums = require("game.utils.enums")
enums.ComponentType = MockComponentType

local CleaningProcessor = require("game.systems.CleaningProcessor")

-- Test suite
TestCleaningProcessor = {}

function TestCleaningProcessor:setUp()
  MockEntityManager:clear()
  self.processor = CleaningProcessor.new()
end

function TestCleaningProcessor:tearDown()
  MockEntityManager:clear()
end

-- Test: Basic processor creation
function TestCleaningProcessor:testProcessorCreation()
  luaunit.assertNotNil(self.processor)
  luaunit.assertEquals(self.processor.defaultCleaningRate, 2.0)
  luaunit.assertEquals(self.processor.processedEntities, 0)
  luaunit.assertEquals(self.processor.completedTasks, 0)
  luaunit.assertEquals(self.processor.totalCleaned, 0)
end

-- Test: Process empty batch
function TestCleaningProcessor:testProcessEmptyBatch()
  self.processor:processBatch({}, 0.1)
  luaunit.assertEquals(self.processor.processedEntities, 0)
  luaunit.assertEquals(self.processor.completedTasks, 0)
end

-- Test: Process nil batch
function TestCleaningProcessor:testProcessNilBatch()
  self.processor:processBatch(nil, 0.1)
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Single entity cleaning processing
function TestCleaningProcessor:testSingleEntityCleaning()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 5.0,
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Create dirt entities within radius
  local dirtEntityId = 500
  MockEntityManager.dirtEntities = {dirtEntityId}
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.POSITION, MockVec2.new(12, 12))
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.DIRT, {
    dirtiness = 10.0,
    maxDirtiness = 10.0
  })
  
  -- Process one frame
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  luaunit.assertTrue(cleaningTask.totalCleaned ~= nil)
  luaunit.assertTrue(cleaningTask.totalCleaned > 0)
end

-- Test: Cleaning with tool bonus
function TestCleaningProcessor:testCleaningWithToolBonus()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 5.0,
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up tool with cleaning bonus
  local tool = {
    toolType = "broom",
    cleaningBonus = 2.0,
    durability = 100
  }
  MockEntityManager:setComponent(entityId, MockComponentType.TOOL, tool)
  
  -- Create dirt entities within radius
  local dirtEntityId = 500
  MockEntityManager.dirtEntities = {dirtEntityId}
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.POSITION, MockVec2.new(12, 12))
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.DIRT, {
    dirtiness = 10.0,
    maxDirtiness = 10.0
  })
  
  -- Process cleaning
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  luaunit.assertTrue(cleaningTask.totalCleaned > 2.0) -- Should be faster with tool bonus
end

-- Test: Cleaning with skills bonus
function TestCleaningProcessor:testCleaningWithSkillsBonus()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 5.0,
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up skills with cleaning bonus
  local skills = {
    cleaning = 80 -- High cleaning skill
  }
  MockEntityManager:setComponent(entityId, MockComponentType.SKILLS, skills)
  
  -- Create dirt entities within radius
  local dirtEntityId = 500
  MockEntityManager.dirtEntities = {dirtEntityId}
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.POSITION, MockVec2.new(12, 12))
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.DIRT, {
    dirtiness = 10.0,
    maxDirtiness = 10.0
  })
  
  -- Process cleaning
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  luaunit.assertTrue(cleaningTask.totalCleaned > 0) -- Should make progress with skills
end

-- Test: Dirt entity removal when fully cleaned
function TestCleaningProcessor:testDirtEntityRemoval()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 5.0,
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Create dirt entity with low dirtiness (easy to clean)
  local dirtEntityId = 500
  MockEntityManager.dirtEntities = {dirtEntityId}
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.POSITION, MockVec2.new(12, 12))
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.DIRT, {
    dirtiness = 1.0, -- Low dirtiness
    maxDirtiness = 10.0
  })
  
  -- Process enough to clean completely
  self.processor:processBatch({entityId}, 2.0)
  
  -- Dirt entity should be removed
  local dirtComponent = MockEntityManager:getComponent(dirtEntityId, MockComponentType.DIRT)
  luaunit.assertTrue(dirtComponent == nil or dirtComponent.dirtiness <= 0)
  luaunit.assertEquals(#MockEntityManager.dirtEntities, 0) -- Should be removed from tracking
end

-- Test: Area cleaning completion
function TestCleaningProcessor:testAreaCleaningCompletion()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 5.0,
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- No dirt entities in the area - should complete immediately
  MockEntityManager.dirtEntities = {}
  
  -- Process cleaning
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertTrue(cleaningTask.isComplete)
  luaunit.assertEquals(self.processor.completedTasks, 1)
end

-- Test: Multiple dirt entities in range
function TestCleaningProcessor:testMultipleDirtEntities()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 5.0,
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Create multiple dirt entities within radius
  local dirtEntityIds = {500, 501, 502}
  MockEntityManager.dirtEntities = dirtEntityIds
  
  for i, dirtId in ipairs(dirtEntityIds) do
    MockEntityManager:setComponent(dirtId, MockComponentType.POSITION, MockVec2.new(10 + i, 10 + i))
    MockEntityManager:setComponent(dirtId, MockComponentType.DIRT, {
      dirtiness = 5.0,
      maxDirtiness = 10.0
    })
  end
  
  -- Process cleaning
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  
  -- Should have cleaned multiple dirt entities
  local totalDirtCleaned = 0
  for _, dirtId in ipairs(dirtEntityIds) do
    local dirtComponent = MockEntityManager:getComponent(dirtId, MockComponentType.DIRT)
    if dirtComponent then
      totalDirtCleaned = totalDirtCleaned + (5.0 - dirtComponent.dirtiness)
    else
      totalDirtCleaned = totalDirtCleaned + 5.0 -- Fully cleaned
    end
  end
  
  luaunit.assertTrue(totalDirtCleaned > 0)
end

-- Test: Dirt entities outside radius not affected
function TestCleaningProcessor:testDirtEntitiesOutsideRadius()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 2.0, -- Small radius
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Create dirt entities: one inside, one outside radius
  local dirtInsideId = 500
  local dirtOutsideId = 501
  MockEntityManager.dirtEntities = {dirtInsideId, dirtOutsideId}
  
  -- Inside radius
  MockEntityManager:setComponent(dirtInsideId, MockComponentType.POSITION, MockVec2.new(11, 11))
  MockEntityManager:setComponent(dirtInsideId, MockComponentType.DIRT, {
    dirtiness = 5.0,
    maxDirtiness = 10.0
  })
  
  -- Outside radius
  MockEntityManager:setComponent(dirtOutsideId, MockComponentType.POSITION, MockVec2.new(20, 20))
  MockEntityManager:setComponent(dirtOutsideId, MockComponentType.DIRT, {
    dirtiness = 5.0,
    maxDirtiness = 10.0
  })
  
  -- Process cleaning
  self.processor:processBatch({entityId}, 1.0)
  
  -- Dirt inside should be affected, dirt outside should not
  local dirtInside = MockEntityManager:getComponent(dirtInsideId, MockComponentType.DIRT)
  local dirtOutside = MockEntityManager:getComponent(dirtOutsideId, MockComponentType.DIRT)
  
  luaunit.assertTrue(dirtInside == nil or dirtInside.dirtiness < 5.0) -- Should be cleaned
  luaunit.assertEquals(dirtOutside.dirtiness, 5.0) -- Should be unchanged
end

-- Test: Batch processing multiple entities
function TestCleaningProcessor:testBatchProcessing()
  local entities = {101, 102, 103}
  
  for i, entityId in ipairs(entities) do
    local targetPosition = MockVec2.new(10 + i * 10, 10 + i * 10)
    
    -- Set up cleaning task
    local cleaningTask = {
      targetPosition = targetPosition,
      radius = 5.0,
      isComplete = false
    }
    MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
    
    -- Set up entity position
    local position = MockVec2.new(10 + i * 10, 10 + i * 10)
    MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
    
    -- Create dirt entity for each cleaner
    local dirtEntityId = 500 + i
    table.insert(MockEntityManager.dirtEntities, dirtEntityId)
    MockEntityManager:setComponent(dirtEntityId, MockComponentType.POSITION, MockVec2.new(12 + i * 10, 12 + i * 10))
    MockEntityManager:setComponent(dirtEntityId, MockComponentType.DIRT, {
      dirtiness = 5.0,
      maxDirtiness = 10.0
    })
  end
  
  -- Process batch
  self.processor:processBatch(entities, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 3)
  
  -- Verify all entities were processed
  for i, entityId in ipairs(entities) do
    local cleaningTask = MockEntityManager:getComponent(entityId, MockComponentType.CLEANING_TASK)
    luaunit.assertTrue(cleaningTask.totalCleaned > 0)
  end
end

-- Test: Invalid entity handling
function TestCleaningProcessor:testInvalidEntityHandling()
  local entityId = 100
  
  -- Entity without cleaning task should be skipped
  self.processor:processBatch({entityId}, 0.1)
  
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Already completed task handling
function TestCleaningProcessor:testCompletedTaskHandling()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up completed cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 5.0,
    totalCleaned = 25.0,
    isComplete = true
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Process batch - should skip completed task
  self.processor:processBatch({entityId}, 0.1)
  
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Performance with large batch
function TestCleaningProcessor:testLargeBatchPerformance()
  local entities = {}
  local batchSize = 50
  
  -- Create large batch of cleaning entities
  for i = 1, batchSize do
    local entityId = 1000 + i
    table.insert(entities, entityId)
    
    local targetPosition = MockVec2.new(i * 5, i * 5)
    
    -- Set up cleaning task
    local cleaningTask = {
      targetPosition = targetPosition,
      radius = 3.0,
      isComplete = false
    }
    MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
    
    -- Set up entity position
    local position = MockVec2.new(i * 5, i * 5)
    MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
    
    -- Create dirt entity for each cleaner
    local dirtEntityId = 2000 + i
    table.insert(MockEntityManager.dirtEntities, dirtEntityId)
    MockEntityManager:setComponent(dirtEntityId, MockComponentType.POSITION, MockVec2.new(i * 5 + 1, i * 5 + 1))
    MockEntityManager:setComponent(dirtEntityId, MockComponentType.DIRT, {
      dirtiness = 3.0,
      maxDirtiness = 10.0
    })
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
function TestCleaningProcessor:testStatisticsTracking()
  local entityId = 100
  local targetPosition = MockVec2.new(10, 10)
  
  -- Set up cleaning task
  local cleaningTask = {
    targetPosition = targetPosition,
    radius = 5.0,
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CLEANING_TASK, cleaningTask)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Create dirt entity to clean
  local dirtEntityId = 500
  MockEntityManager.dirtEntities = {dirtEntityId}
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.POSITION, MockVec2.new(12, 12))
  MockEntityManager:setComponent(dirtEntityId, MockComponentType.DIRT, {
    dirtiness = 1.0, -- Low dirtiness for easy completion
    maxDirtiness = 10.0
  })
  
  -- Process to generate stats
  self.processor:processBatch({entityId}, 2.0)
  
  local stats = self.processor:getStats()
  luaunit.assertNotNil(stats)
  luaunit.assertEquals(stats.processedEntities, 1)
  luaunit.assertTrue(stats.totalCleaned > 0)
  
  -- Should complete since no dirt left
  if #MockEntityManager.dirtEntities == 0 then
    luaunit.assertEquals(stats.completedTasks, 1)
  end
end

-- Run the tests
luaunit.LuaUnit.run()