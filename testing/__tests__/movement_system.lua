-- Test file for MovementSystem
-- Tests the batch movement processing and integration functionality

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
  MOVEMENT_TASK = 1,
  POSITION = 2,
  VELOCITY = 3,
  SPEEDSTAT = 4,
  TOPOGRAPHY = 5,
  MAPTILE_TAG = 6
}

-- Mock topography types
local MockTopographyType = {
  GRASSLAND = 1,
  WATER = 2,
  MOUNTAIN = 3,
  INACCESSIBLE = 4
}

-- Mock enums module
package.loaded["game.utils.enums"] = {
  ComponentType = MockComponentType,
  TopographyType = MockTopographyType
}

-- Mock constants module
package.loaded["game.utils.constants"] = {
  DEFAULT_MOVEMENT_SPEED = 2.0,
  TICKSPEED = 60
}

-- Mock Vec2 module
package.loaded["game.utils.Vec2"] = MockVec2

-- Mock logger module
package.loaded["game.logger"] = MockLogger

-- Mock PathFinder
local MockPathFinder = {}
MockPathFinder.__index = MockPathFinder

function MockPathFinder.new()
  return setmetatable({}, MockPathFinder)
end

function MockPathFinder:findPath(fromPos, toPos)
  -- Mock pathfinding that creates a simple path for testing
  if fromPos and toPos then
    return {
      {x = math.floor(toPos.x), y = math.floor(toPos.y)}
    }
  end
  return nil
end

package.loaded["game.systems.PathFinder"] = MockPathFinder

-- Mock EntityManager for testing
local MockEntityManager = {
  entities = {},
  _components = {}
}

function MockEntityManager:getComponent(entityId, componentType)
  if self._components[componentType] then
    return self._components[componentType][entityId]
  end
  return nil
end

function MockEntityManager:addComponent(entityId, componentType, component)
  if not self._components[componentType] then
    self._components[componentType] = {}
  end
  self._components[componentType][entityId] = component
end

function MockEntityManager:removeComponent(entityId, componentType)
  if self._components[componentType] then
    self._components[componentType][entityId] = nil
  end
end

function MockEntityManager:find(componentType, position)
  -- Mock tile finding for movement validation
  if componentType == MockComponentType.MAPTILE_TAG then
    return 999 -- Return a mock tile entity ID
  end
  return nil
end

function MockEntityManager:reset()
  self._components = {}
  self.entities = {}
end

-- Set global EntityManager
_G.EntityManager = MockEntityManager

-- Mock MapManager
_G.MapManager = {
  width = 100,
  height = 100
}

-- Mock TaskComponentPool
local MockTaskComponentPool = {
  release = function(self, component, componentType)
    -- Mock pooling behavior
  end
}

package.loaded["game.systems.TaskComponentPool"] = MockTaskComponentPool

-- Mock MovementTask component for testing
local MockMovementTask = {}
MockMovementTask.__index = MockMovementTask

function MockMovementTask.new(targetPosition)
  local self = setmetatable({}, MockMovementTask)
  self.targetPosition = targetPosition
  self.currentWaypointIndex = 1
  self.path = {}
  self.isComplete = false
  self.movementSpeed = 1.0
  self._poolable = true
  return self
end

function MockMovementTask:hasValidPath()
  return self.path and #self.path > 0
end

function MockMovementTask:setPath(path)
  self.path = path or {}
  self.currentWaypointIndex = 1
end

function MockMovementTask:getCurrentTarget()
  if self.path and self.currentWaypointIndex <= #self.path then
    return self.path[self.currentWaypointIndex]
  end
  return nil
end

function MockMovementTask:update(currentPosition)
  if not self.path or #self.path == 0 then
    self.isComplete = true
    return false
  end
  
  local currentTarget = self:getCurrentTarget()
  if not currentTarget then
    self.isComplete = true
    return false
  end
  
  -- Check if we've reached the current waypoint
  local distance = math.sqrt(
    (currentPosition.x - currentTarget.x)^2 + 
    (currentPosition.y - currentTarget.y)^2
  )
  
  if distance < 0.1 then  -- Waypoint threshold
    self.currentWaypointIndex = self.currentWaypointIndex + 1
    if self.currentWaypointIndex > #self.path then
      self.isComplete = true
      return false
    end
  end
  
  return true
end

function MockMovementTask:markComplete()
  self.isComplete = true
end

-- Test suite for MovementSystem
TestMovementSystem = {}

function TestMovementSystem:setUp()
  -- Reset mock state before each test
  MockEntityManager:reset()
  
  -- Import MovementSystem after mocks are set up
  local MovementSystem = require("game.systems.MovementSystem")
  self.movementSystem = MovementSystem.new()
end

function TestMovementSystem:tearDown()
  -- Clean up after each test
  MockEntityManager:reset()
end

-- Test MovementSystem creation
function TestMovementSystem:testMovementSystemCreation()
  luaunit.assertNotNil(self.movementSystem)
  luaunit.assertEquals(self.movementSystem.movementSpeed, 1.0)
  luaunit.assertEquals(self.movementSystem.waypointThreshold, 0.1)
end

-- Test basic movement processing
function TestMovementSystem:testBasicMovementProcessing()
  local entityId = 1
  local startPos = MockVec2.new(0, 0)
  local targetPos = MockVec2.new(5, 5)
  
  -- Create components
  local position = MockVec2.new(startPos.x, startPos.y)
  local velocity = MockVec2.new(0, 0)
  local movementTask = MockMovementTask.new(targetPos)
  
  -- Add components to entity
  MockEntityManager:addComponent(entityId, MockComponentType.POSITION, position)
  MockEntityManager:addComponent(entityId, MockComponentType.VELOCITY, velocity)
  MockEntityManager:addComponent(entityId, MockComponentType.MOVEMENT_TASK, movementTask)
  MockEntityManager:addComponent(entityId, MockComponentType.SPEEDSTAT, 2.0)
  
  -- Add a mock topography for the target tile
  MockEntityManager:addComponent(999, MockComponentType.TOPOGRAPHY, {
    speedMultiplier = 1.0,
    type = MockTopographyType.GRASSLAND
  })
  
  -- Process movement
  local result = self.movementSystem:process(entityId, movementTask, 0.1)
  
  luaunit.assertTrue(result)
  luaunit.assertTrue(movementTask:hasValidPath())
end

-- Test movement validation with blocked terrain
function TestMovementSystem:testMovementValidationBlocked()
  local fromPos = MockVec2.new(0, 0)
  local toPos = MockVec2.new(1, 1)
  
  -- Add blocked topography
  MockEntityManager:addComponent(999, MockComponentType.TOPOGRAPHY, {
    speedMultiplier = 0,  -- Impassable
    type = MockTopographyType.WATER
  })
  
  local isValid = self.movementSystem:isValidMovement(fromPos, toPos)
  luaunit.assertFalse(isValid)
end

-- Test movement validation with passable terrain
function TestMovementSystem:testMovementValidationPassable()
  local fromPos = MockVec2.new(0, 0)
  local toPos = MockVec2.new(1, 1)
  
  -- Add passable topography
  MockEntityManager:addComponent(999, MockComponentType.TOPOGRAPHY, {
    speedMultiplier = 1.0,
    type = MockTopographyType.GRASSLAND
  })
  
  local isValid = self.movementSystem:isValidMovement(fromPos, toPos)
  luaunit.assertTrue(isValid)
end

-- Test inaccessible terrain blocking
function TestMovementSystem:testInaccessibleTerrainBlocking()
  local fromPos = MockVec2.new(0, 0)
  local toPos = MockVec2.new(1, 1)
  
  -- Add inaccessible topography
  MockEntityManager:addComponent(999, MockComponentType.TOPOGRAPHY, {
    speedMultiplier = 1.0,
    type = MockTopographyType.INACCESSIBLE
  })
  
  local isValid = self.movementSystem:isValidMovement(fromPos, toPos)
  luaunit.assertFalse(isValid)
end

-- Test batch processing of multiple entities
function TestMovementSystem:testBatchProcessing()
  local entities = {1, 2, 3}
  
  for i, entityId in ipairs(entities) do
    local position = MockVec2.new(i, i)
    local velocity = MockVec2.new(0, 0)
    local movementTask = MockMovementTask.new(MockVec2.new(i + 5, i + 5))
    
    MockEntityManager:addComponent(entityId, MockComponentType.POSITION, position)
    MockEntityManager:addComponent(entityId, MockComponentType.VELOCITY, velocity)
    MockEntityManager:addComponent(entityId, MockComponentType.MOVEMENT_TASK, movementTask)
    MockEntityManager:addComponent(entityId, MockComponentType.SPEEDSTAT, 2.0)
    MockEntityManager.entities[entityId] = true
  end
  
  -- Add passable topography
  MockEntityManager:addComponent(999, MockComponentType.TOPOGRAPHY, {
    speedMultiplier = 1.0,
    type = MockTopographyType.GRASSLAND
  })
  
  self.movementSystem:processBatch(entities, 0.1)
  
  local stats = self.movementSystem:getStats()
  luaunit.assertEquals(stats.processedEntities, 3)
end

-- Test movement towards target calculation
function TestMovementSystem:testMoveTowardsTarget()
  local entityId = 1
  local position = MockVec2.new(0, 0)
  local velocity = MockVec2.new(0, 0)
  local target = MockVec2.new(3, 4)  -- Distance of 5 units
  
  MockEntityManager:addComponent(entityId, MockComponentType.SPEEDSTAT, 5.0)
  MockEntityManager:addComponent(999, MockComponentType.TOPOGRAPHY, {
    speedMultiplier = 1.0,
    type = MockTopographyType.GRASSLAND
  })
  
  -- Move for 1 second at speed 5 should cover the full distance
  self.movementSystem:moveTowardsTarget(entityId, position, velocity, target, 1.0, 1.0)
  
  -- Should have moved towards target
  luaunit.assertTrue(position.x > 0 or position.y > 0)
end

-- Test path generation
function TestMovementSystem:testPathGeneration()
  local entityId = 1
  local position = MockVec2.new(0, 0)
  local movementTask = MockMovementTask.new(MockVec2.new(5, 5))
  
  local success = self.movementSystem:generatePath(entityId, movementTask, position)
  
  luaunit.assertTrue(success)
  luaunit.assertTrue(movementTask:hasValidPath())
  luaunit.assertTrue(#movementTask.path > 0)
end

-- Test finding moving entities
function TestMovementSystem:testFindMovingEntities()
  local entityId1 = 1
  local entityId2 = 2
  local entityId3 = 3
  
  -- Entity 1: Has movement task (should be found)
  MockEntityManager.entities[entityId1] = true
  MockEntityManager:addComponent(entityId1, MockComponentType.MOVEMENT_TASK, MockMovementTask.new(MockVec2.new(1, 1)))
  
  -- Entity 2: Has completed movement task (should not be found)
  local completedTask = MockMovementTask.new(MockVec2.new(2, 2))
  completedTask.isComplete = true
  MockEntityManager.entities[entityId2] = true
  MockEntityManager:addComponent(entityId2, MockComponentType.MOVEMENT_TASK, completedTask)
  
  -- Entity 3: No movement task (should not be found)
  MockEntityManager.entities[entityId3] = true
  
  local movingEntities = self.movementSystem:findMovingEntities()
  
  luaunit.assertEquals(#movingEntities, 1)
  luaunit.assertEquals(movingEntities[1], entityId1)
end

-- Test bounds checking
function TestMovementSystem:testBoundsChecking()
  -- Test in-bounds position
  local inBounds = self.movementSystem:isInBounds(MockVec2.new(50, 50))
  luaunit.assertTrue(inBounds)
  
  -- Test out-of-bounds positions
  local outOfBoundsX = self.movementSystem:isInBounds(MockVec2.new(150, 50))
  luaunit.assertFalse(outOfBoundsX)
  
  local outOfBoundsY = self.movementSystem:isInBounds(MockVec2.new(50, 150))
  luaunit.assertFalse(outOfBoundsY)
  
  local negativePos = self.movementSystem:isInBounds(MockVec2.new(-1, 50))
  luaunit.assertFalse(negativePos)
end

-- Test nearest passable position finding
function TestMovementSystem:testFindNearestPassablePosition()
  local targetPos = MockVec2.new(50, 50)
  
  -- Add passable topography for nearby positions
  MockEntityManager:addComponent(999, MockComponentType.TOPOGRAPHY, {
    speedMultiplier = 1.0,
    type = MockTopographyType.GRASSLAND
  })
  
  local nearestPos = self.movementSystem:findNearestPassablePosition(targetPos, 3)
  
  luaunit.assertNotNil(nearestPos)
  luaunit.assertTrue(nearestPos.x >= 47 and nearestPos.x <= 53)  -- Within radius
  luaunit.assertTrue(nearestPos.y >= 47 and nearestPos.y <= 53)  -- Within radius
end

-- Test movement completion and cleanup
function TestMovementSystem:testMovementCompletion()
  local entityId = 1
  local velocity = MockVec2.new(2, 3)
  local movementTask = MockMovementTask.new(MockVec2.new(5, 5))
  
  MockEntityManager:addComponent(entityId, MockComponentType.MOVEMENT_TASK, movementTask)
  
  self.movementSystem:completeMovement(entityId, movementTask, velocity)
  
  -- Velocity should be stopped
  luaunit.assertEquals(velocity.x, 0)
  luaunit.assertEquals(velocity.y, 0)
  
  -- MovementTask should be removed
  local removedTask = MockEntityManager:getComponent(entityId, MockComponentType.MOVEMENT_TASK)
  luaunit.assertNil(removedTask)
end

-- Test configuration updates
function TestMovementSystem:testConfiguration()
  local config = {
    movementSpeed = 2.5,
    waypointThreshold = 0.2
  }
  
  self.movementSystem:configure(config)
  
  luaunit.assertEquals(self.movementSystem.movementSpeed, 2.5)
  luaunit.assertEquals(self.movementSystem.waypointThreshold, 0.2)
end

-- Test TaskExecutionSystem registration
function TestMovementSystem:testTaskExecutionSystemRegistration()
  local mockTaskExecutionSystem = {
    registerProcessor = function(self, componentType, processor)
      self.registeredProcessors = self.registeredProcessors or {}
      self.registeredProcessors[componentType] = processor
      return true
    end
  }
  
  local success = self.movementSystem:registerWithTaskExecutionSystem(mockTaskExecutionSystem)
  
  luaunit.assertTrue(success)
  luaunit.assertNotNil(mockTaskExecutionSystem.registeredProcessors)
  luaunit.assertEquals(mockTaskExecutionSystem.registeredProcessors[MockComponentType.MOVEMENT_TASK], self.movementSystem)
end

-- Test error handling for invalid TaskExecutionSystem
function TestMovementSystem:testInvalidTaskExecutionSystemRegistration()
  local success = self.movementSystem:registerWithTaskExecutionSystem(nil)
  luaunit.assertFalse(success)
end

-- Test main update function
function TestMovementSystem:testMainUpdate()
  local entityId = 1
  MockEntityManager.entities[entityId] = true
  MockEntityManager:addComponent(entityId, MockComponentType.MOVEMENT_TASK, MockMovementTask.new(MockVec2.new(1, 1)))
  MockEntityManager:addComponent(entityId, MockComponentType.POSITION, MockVec2.new(0, 0))
  MockEntityManager:addComponent(entityId, MockComponentType.SPEEDSTAT, 2.0)
  
  -- Add passable topography
  MockEntityManager:addComponent(999, MockComponentType.TOPOGRAPHY, {
    speedMultiplier = 1.0,
    type = MockTopographyType.GRASSLAND
  })
  
  -- Should not crash
  self.movementSystem:update(0.1)
  
  local stats = self.movementSystem:getStats()
  luaunit.assertEquals(stats.processedEntities, 1)
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())