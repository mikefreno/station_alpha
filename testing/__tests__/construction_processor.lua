-- Test file for ConstructionProcessor
-- Tests construction logic, progress tracking, and batch processing functionality

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
  CONSTRUCTION_TASK = "construction_task",
  POSITION = "position",
  TOOL = "tool",
  SKILLS = "skills",
  INVENTORY = "inventory",
  BUILDABLE = "buildable",
  BUILDING = "building"
}

-- Mock EntityManager
local MockEntityManager = {
  components = {}
}

function MockEntityManager:getComponent(entityId, componentType)
  local key = entityId .. "_" .. componentType
  return self.components[key]
end

function MockEntityManager:setComponent(entityId, componentType, component)
  if not entityId or not componentType then
    return
  end
  
  -- Add markComplete method to construction tasks
  if componentType == MockComponentType.CONSTRUCTION_TASK and component and not component.markComplete then
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
  createBuilding = function(self, position, buildingType)
    return 9999 -- Mock building entity ID
  end
}

-- Set up global mocks
_G.Logger = MockLogger
_G.Vec2 = MockVec2
_G.EntityManager = MockEntityManager
_G.TaskComponentPool = MockTaskComponentPool
_G.MapManager = MockMapManager

-- Load component enums and ConstructionProcessor
local enums = require("game.utils.enums")
enums.ComponentType = MockComponentType

local ConstructionProcessor = require("game.systems.ConstructionProcessor")

-- Test suite
TestConstructionProcessor = {}

function TestConstructionProcessor:setUp()
  MockEntityManager:clear()
  self.processor = ConstructionProcessor.new()
end

function TestConstructionProcessor:tearDown()
  MockEntityManager:clear()
end

-- Test: Basic processor creation
function TestConstructionProcessor:testProcessorCreation()
  luaunit.assertNotNil(self.processor)
  luaunit.assertEquals(self.processor.defaultBuildRate, 0.1)
  luaunit.assertEquals(self.processor.processedEntities, 0)
  luaunit.assertEquals(self.processor.completedTasks, 0)
  luaunit.assertEquals(self.processor.buildingsCreated, 0)
end

-- Test: Process empty batch
function TestConstructionProcessor:testProcessEmptyBatch()
  self.processor:processBatch({}, 0.1)
  luaunit.assertEquals(self.processor.processedEntities, 0)
  luaunit.assertEquals(self.processor.completedTasks, 0)
end

-- Test: Process nil batch
function TestConstructionProcessor:testProcessNilBatch()
  self.processor:processBatch(nil, 0.1)
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Single entity construction processing
function TestConstructionProcessor:testSingleEntityConstruction()
  local entityId = 100
  local targetId = 200
  
  -- Set up construction task
  local constructionTask = {
    target = targetId,
    buildingType = "house",
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
  
  -- Set up target buildable component
  local buildable = {
    buildingType = "house",
    buildTime = 10.0,
    requiredMaterials = {wood = 20, stone = 10}
  }
  MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up entity inventory with materials
  local inventory = {
    items = {wood = 25, stone = 15}
  }
  MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
  
  -- Process one frame
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  luaunit.assertTrue(constructionTask.progress ~= nil)
  luaunit.assertTrue(constructionTask.progress > 0)
end

-- Test: Construction with insufficient materials
function TestConstructionProcessor:testInsufficientMaterials()
  local entityId = 100
  local targetId = 200
  
  -- Set up construction task
  local constructionTask = {
    target = targetId,
    buildingType = "house",
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
  
  -- Set up target buildable component
  local buildable = {
    buildingType = "house",
    buildTime = 10.0,
    requiredMaterials = {wood = 20, stone = 10}
  }
  MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up entity inventory with insufficient materials
  local inventory = {
    items = {wood = 5, stone = 2} -- Not enough materials
  }
  MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
  
  -- Process one frame
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  -- Progress should be 0 due to insufficient materials
  luaunit.assertTrue(constructionTask.progress == nil or constructionTask.progress == 0)
end

-- Test: Construction with tool bonus
function TestConstructionProcessor:testConstructionWithToolBonus()
  local entityId = 100
  local targetId = 200
  
  -- Set up construction task
  local constructionTask = {
    target = targetId,
    buildingType = "house",
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
  
  -- Set up target buildable component
  local buildable = {
    buildingType = "house",
    buildTime = 10.0,
    requiredMaterials = {wood = 20, stone = 10}
  }
  MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up entity inventory with materials
  local inventory = {
    items = {wood = 25, stone = 15}
  }
  MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
  
  -- Set up tool with construction bonus
  local tool = {
    toolType = "hammer",
    constructionBonus = 2.0,
    durability = 100
  }
  MockEntityManager:setComponent(entityId, MockComponentType.TOOL, tool)
  
  -- Process construction
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  luaunit.assertTrue(constructionTask.progress > 0.1) -- Should be faster with tool bonus
end

-- Test: Construction with skills bonus
function TestConstructionProcessor:testConstructionWithSkillsBonus()
  local entityId = 100
  local targetId = 200
  
  -- Set up construction task
  local constructionTask = {
    target = targetId,
    buildingType = "house",
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
  
  -- Set up target buildable component
  local buildable = {
    buildingType = "house",
    buildTime = 10.0,
    requiredMaterials = {wood = 20, stone = 10}
  }
  MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up entity inventory with materials
  local inventory = {
    items = {wood = 25, stone = 15}
  }
  MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
  
  -- Set up skills with construction bonus
  local skills = {
    construction = 80 -- High construction skill
  }
  MockEntityManager:setComponent(entityId, MockComponentType.SKILLS, skills)
  
  -- Process construction
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 1)
  luaunit.assertTrue(constructionTask.progress > 0) -- Should make progress with skills
end

-- Test: Building completion and creation
function TestConstructionProcessor:testBuildingCompletion()
  local entityId = 100
  local targetId = 200
  
  -- Set up construction task with high progress
  local constructionTask = {
    target = targetId,
    buildingType = "house",
    progress = 0.95, -- Almost complete
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
  
  -- Set up target buildable component
  local buildable = {
    buildingType = "house",
    buildTime = 10.0,
    requiredMaterials = {wood = 20, stone = 10}
  }
  MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up entity inventory with materials
  local inventory = {
    items = {wood = 25, stone = 15}
  }
  MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
  
  -- Process to complete construction
  self.processor:processBatch({entityId}, 1.0)
  
  luaunit.assertTrue(constructionTask.isComplete)
  luaunit.assertEquals(self.processor.completedTasks, 1)
  luaunit.assertEquals(self.processor.buildingsCreated, 1)
end

-- Test: Material consumption during construction
function TestConstructionProcessor:testMaterialConsumption()
  local entityId = 100
  local targetId = 200
  
  -- Set up construction task
  local constructionTask = {
    target = targetId,
    buildingType = "house",
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
  
  -- Set up target buildable component
  local buildable = {
    buildingType = "house",
    buildTime = 1.0, -- Quick build for testing
    requiredMaterials = {wood = 10, stone = 5}
  }
  MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up entity inventory with exact materials
  local inventory = {
    items = {wood = 10, stone = 5}
  }
  MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
  
  -- Process enough to complete construction
  self.processor:processBatch({entityId}, 10.0)
  
  luaunit.assertTrue(constructionTask.isComplete)
  -- Materials should be consumed
  luaunit.assertEquals(inventory.items.wood, 0)
  luaunit.assertEquals(inventory.items.stone, 0)
end

-- Test: Batch processing multiple entities
function TestConstructionProcessor:testBatchProcessing()
  local entities = {101, 102, 103}
  
  for i, entityId in ipairs(entities) do
    local targetId = 200 + i
    
    -- Set up construction task
    local constructionTask = {
      target = targetId,
      buildingType = "house",
      isComplete = false
    }
    MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
    
    -- Set up target buildable component
    local buildable = {
      buildingType = "house",
      buildTime = 10.0,
      requiredMaterials = {wood = 20, stone = 10}
    }
    MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
    
    -- Set up entity position
    local position = MockVec2.new(10 + i, 10 + i)
    MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
    
    -- Set up entity inventory with materials
    local inventory = {
      items = {wood = 25, stone = 15}
    }
    MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
  end
  
  -- Process batch
  self.processor:processBatch(entities, 1.0)
  
  luaunit.assertEquals(self.processor.processedEntities, 3)
  
  -- Verify all entities were processed
  for i, entityId in ipairs(entities) do
    local constructionTask = MockEntityManager:getComponent(entityId, MockComponentType.CONSTRUCTION_TASK)
    luaunit.assertTrue(constructionTask.progress > 0)
  end
end

-- Test: Invalid entity handling
function TestConstructionProcessor:testInvalidEntityHandling()
  local entityId = 100
  
  -- Entity without construction task should be skipped
  self.processor:processBatch({entityId}, 0.1)
  
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Already completed task handling
function TestConstructionProcessor:testCompletedTaskHandling()
  local entityId = 100
  local targetId = 200
  
  -- Set up completed construction task
  local constructionTask = {
    target = targetId,
    buildingType = "house",
    progress = 1.0,
    isComplete = true
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
  
  -- Process batch - should skip completed task
  self.processor:processBatch({entityId}, 0.1)
  
  luaunit.assertEquals(self.processor.processedEntities, 0)
end

-- Test: Performance with large batch
function TestConstructionProcessor:testLargeBatchPerformance()
  local entities = {}
  local batchSize = 50
  
  -- Create large batch of construction entities
  for i = 1, batchSize do
    local entityId = 1000 + i
    local targetId = 2000 + i
    table.insert(entities, entityId)
    
    -- Set up construction task
    local constructionTask = {
      target = targetId,
      buildingType = "house",
      isComplete = false
    }
    MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
    
    -- Set up target buildable component
    local buildable = {
      buildingType = "house",
      buildTime = 10.0,
      requiredMaterials = {wood = 20, stone = 10}
    }
    MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
    
    -- Set up entity position
    local position = MockVec2.new(i, i)
    MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
    
    -- Set up entity inventory with materials
    local inventory = {
      items = {wood = 25, stone = 15}
    }
    MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
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
function TestConstructionProcessor:testStatisticsTracking()
  local entityId = 100
  local targetId = 200
  
  -- Set up construction task for completion
  local constructionTask = {
    target = targetId,
    buildingType = "house",
    progress = 0.98, -- Almost complete
    isComplete = false
  }
  MockEntityManager:setComponent(entityId, MockComponentType.CONSTRUCTION_TASK, constructionTask)
  
  -- Set up target buildable component
  local buildable = {
    buildingType = "house",
    buildTime = 10.0,
    requiredMaterials = {wood = 20, stone = 10}
  }
  MockEntityManager:setComponent(targetId, MockComponentType.BUILDABLE, buildable)
  
  -- Set up entity position
  local position = MockVec2.new(10, 10)
  MockEntityManager:setComponent(entityId, MockComponentType.POSITION, position)
  
  -- Set up entity inventory with materials
  local inventory = {
    items = {wood = 25, stone = 15}
  }
  MockEntityManager:setComponent(entityId, MockComponentType.INVENTORY, inventory)
  
  -- Process to generate stats
  self.processor:processBatch({entityId}, 1.0)
  
  local stats = self.processor:getStats()
  luaunit.assertNotNil(stats)
  luaunit.assertEquals(stats.processedEntities, 1)
  luaunit.assertEquals(stats.completedTasks, 1)
  luaunit.assertEquals(stats.buildingsCreated, 1)
end

-- Run the tests
luaunit.LuaUnit.run()