-- Unit tests for SpatialIndex system
-- Tests correctness of spatial indexing functionality

require("testing.loveStub")
local luaunit = require("testing.luaunit")

local SpatialIndex = require("game.systems.SpatialIndex")
local Vec2 = require("game.utils.Vec2")

local TestSpatialIndex = {}

function TestSpatialIndex:setUp()
  self.spatialIndex = SpatialIndex:new(4) -- 4x4 tile grid for testing
end

function TestSpatialIndex:tearDown()
  self.spatialIndex = nil
end

-- Test basic entity addition and retrieval
function TestSpatialIndex:testBasicEntityAddition()
  local entity1 = 1
  local entity2 = 2

  self.spatialIndex:addEntity(entity1, 5, 5)
  self.spatialIndex:addEntity(entity2, 10, 10)

  -- Test entities are in correct grid cells
  local nearby1 = self.spatialIndex:getNearbyEntities(5, 5, 1)
  local nearby2 = self.spatialIndex:getNearbyEntities(10, 10, 1)

  luaunit.assertNotNil(nearby1)
  luaunit.assertNotNil(nearby2)
  luaunit.assertTrue(#nearby1 >= 1)
  luaunit.assertTrue(#nearby2 >= 1)
end

-- Test entity removal
function TestSpatialIndex:testEntityRemoval()
  local entity1 = 1

  self.spatialIndex:addEntity(entity1, 5, 5)
  local nearbyBefore = self.spatialIndex:getNearbyEntities(5, 5, 1)
  luaunit.assertTrue(#nearbyBefore >= 1)

  self.spatialIndex:removeEntity(entity1)
  local nearbyAfter = self.spatialIndex:getNearbyEntities(5, 5, 1)

  -- Entity should no longer be found
  local found = false
  for _, entity in ipairs(nearbyAfter) do
    if entity == entity1 then
      found = true
      break
    end
  end
  luaunit.assertFalse(found)
end

-- Test entity position updates
function TestSpatialIndex:testEntityPositionUpdate()
  local entity1 = 1

  -- Add entity at initial position
  self.spatialIndex:addEntity(entity1, 5, 5)
  local nearbyOriginal = self.spatialIndex:getNearbyEntities(5, 5, 1)
  luaunit.assertTrue(#nearbyOriginal >= 1)

  -- Update entity position
  self.spatialIndex:updateEntity(entity1, 15, 15)

  -- Should no longer be near original position
  local nearbyOld = self.spatialIndex:getNearbyEntities(5, 5, 1)
  local foundInOld = false
  for _, entity in ipairs(nearbyOld) do
    if entity == entity1 then
      foundInOld = true
      break
    end
  end
  luaunit.assertFalse(foundInOld)

  -- Should be near new position
  local nearbyNew = self.spatialIndex:getNearbyEntities(15, 15, 1)
  local foundInNew = false
  for _, entity in ipairs(nearbyNew) do
    if entity == entity1 then
      foundInNew = true
      break
    end
  end
  luaunit.assertTrue(foundInNew)
end

-- Test proximity queries with different radii
function TestSpatialIndex:testProximityQueries()
  local entity1 = 1
  local entity2 = 2
  local entity3 = 3

  -- Place entities at known positions
  self.spatialIndex:addEntity(entity1, 10, 10)
  self.spatialIndex:addEntity(entity2, 12, 10) -- 2 units away
  self.spatialIndex:addEntity(entity3, 20, 10) -- 10 units away

  -- Query with small radius should only find entity1 and entity2
  local nearbySmall = self.spatialIndex:getNearbyEntities(10, 10, 3)
  local foundCount = 0
  for _, entity in ipairs(nearbySmall) do
    if entity == entity1 or entity == entity2 then
      foundCount = foundCount + 1
    end
  end
  luaunit.assertTrue(foundCount >= 2)

  -- Query with large radius should find all entities
  local nearbyLarge = self.spatialIndex:getNearbyEntities(10, 10, 15)
  local foundAll = 0
  for _, entity in ipairs(nearbyLarge) do
    if entity == entity1 or entity == entity2 or entity == entity3 then
      foundAll = foundAll + 1
    end
  end
  luaunit.assertTrue(foundAll >= 3)
end

-- Test closest entity finding
function TestSpatialIndex:testClosestEntity()
  local entity1 = 1
  local entity2 = 2
  local entity3 = 3

  -- Place entities at known distances from query point (5, 5)
  self.spatialIndex:addEntity(entity1, 7, 5) -- distance 2
  self.spatialIndex:addEntity(entity2, 5, 8) -- distance 3
  self.spatialIndex:addEntity(entity3, 10, 5) -- distance 5

  local closest = self.spatialIndex:getClosestEntity(5, 5)
  luaunit.assertEqual(closest, entity1) -- Should be entity1 (closest)
end

-- Test rectangular area queries
function TestSpatialIndex:testRectangularQueries()
  local entity1 = 1
  local entity2 = 2
  local entity3 = 3

  -- Place entities
  self.spatialIndex:addEntity(entity1, 5, 5)   -- inside rect
  self.spatialIndex:addEntity(entity2, 7, 7)   -- inside rect
  self.spatialIndex:addEntity(entity3, 15, 15) -- outside rect

  -- Query rectangular area (0,0) to (10,10)
  local entitiesInRect = self.spatialIndex:getEntitiesInRect(0, 0, 10, 10)

  local foundInside = 0
  local foundOutside = false
  for _, entity in ipairs(entitiesInRect) do
    if entity == entity1 or entity == entity2 then
      foundInside = foundInside + 1
    elseif entity == entity3 then
      foundOutside = true
    end
  end

  luaunit.assertTrue(foundInside >= 2)
  luaunit.assertFalse(foundOutside)
end

-- Test performance with many entities
function TestSpatialIndex:testPerformanceWithManyEntities()
  local entityCount = 1000
  local queryCount = 100

  -- Add many entities
  for i = 1, entityCount do
    self.spatialIndex:addEntity(i, math.random(1, 100), math.random(1, 100))
  end

  -- Perform many queries and measure time
  local startTime = love.timer.getTime()
  for _ = 1, queryCount do
    local x = math.random(1, 100)
    local y = math.random(1, 100)
    self.spatialIndex:getNearbyEntities(x, y, 5)
  end
  local endTime = love.timer.getTime()

  local queryTime = (endTime - startTime) / queryCount
  print(string.format("Average query time with %d entities: %.4f ms", entityCount, queryTime * 1000))

  -- Performance should be reasonable (less than 1ms per query)
  luaunit.assertTrue(queryTime < 0.001)
end

-- Test grid boundary conditions
function TestSpatialIndex:testGridBoundaries()
  local entity1 = 1
  local entity2 = 2

  -- Place entities at grid boundaries
  self.spatialIndex:addEntity(entity1, 0, 0)     -- minimum boundary
  self.spatialIndex:addEntity(entity2, 100, 100) -- beyond typical range

  -- Should still be able to find entities
  local nearbyMin = self.spatialIndex:getNearbyEntities(0, 0, 1)
  local nearbyMax = self.spatialIndex:getNearbyEntities(100, 100, 1)

  luaunit.assertNotNil(nearbyMin)
  luaunit.assertNotNil(nearbyMax)
end

-- Test duplicate entity handling
function TestSpatialIndex:testDuplicateEntityHandling()
  local entity1 = 1

  -- Add same entity twice
  self.spatialIndex:addEntity(entity1, 5, 5)
  self.spatialIndex:addEntity(entity1, 5, 5)

  local nearby = self.spatialIndex:getNearbyEntities(5, 5, 1)

  -- Should not have duplicates
  local count = 0
  for _, entity in ipairs(nearby) do
    if entity == entity1 then
      count = count + 1
    end
  end

  luaunit.assertTrue(count <= 1)
end

-- Test statistics collection
function TestSpatialIndex:testStatisticsCollection()
  local entity1 = 1

  self.spatialIndex:addEntity(entity1, 5, 5)
  self.spatialIndex:getNearbyEntities(5, 5, 1)

  local stats = self.spatialIndex:getStatistics()

  luaunit.assertNotNil(stats)
  luaunit.assertNotNil(stats.total_queries)
  luaunit.assertNotNil(stats.total_entities)
  luaunit.assertTrue(stats.total_queries > 0)
  luaunit.assertTrue(stats.total_entities > 0)
end

-- Run all tests
os.exit(luaunit.LuaUnit.run())