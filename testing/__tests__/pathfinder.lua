package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
Logger = require("logger")
local Vec2 = require("utils.Vec2")
local PathFinder = require("systems.PathFinder")
local enums = require("utils.enums")
local constants = require("utils.constants")

-- Mock the global MapManager to make it available for PathFinder
-- This is a simplified mock that just provides the basic structure needed for tests
local function setupMockMapManager()
  -- Create a minimal mock MapManager that satisfies PathFinder's requirements
  local mockMapManager = {
    width = 5,
    height = 5,
    graph = {},
    entityManager = nil, -- We'll mock this as needed
  }

  -- Mock the worldToGrid function
  mockMapManager.worldToGrid = function(pos)
    local x = math.floor((pos.x + constants.pixelSize / 2) / constants.pixelSize)
    local y = math.floor((pos.y + constants.pixelSize / 2) / constants.pixelSize)
    return Vec2.new(x, y)
  end

  -- Mock the getTileStyle function
  mockMapManager.getTileStyle = function(x, y)
    if x < 1 or x > mockMapManager.width or y < 1 or y > mockMapManager.height then
      return enums.TopographyType.INACCESSIBLE
    end
    return enums.TopographyType.OPEN -- default to open terrain
  end

  _G.MapManager = mockMapManager
end

-- Test case for PathFinder - focusing on error handling and basic behavior
TestPathFinder = {}

function TestPathFinder:testBasicErrorHandling()
  setupMockMapManager()

  local pathFinder = PathFinder.new()

  -- Test with nil MapManager (should return nil)
  _G.MapManager = nil
  local result = pathFinder:findPath(Vec2.new(1, 1), Vec2.new(2, 2))
  luaunit.assertNil(result, "Should return nil when MapManager is nil")

  -- Restore MapManager
  setupMockMapManager()
end

function TestPathFinder:testOutOfBoundsErrorHandling()
  setupMockMapManager()

  local pathFinder = PathFinder.new()

  -- Test with out of bounds start position
  local startWorldPos = Vec2.new(-1 * constants.pixelSize, -1 * constants.pixelSize) -- (-1,-1)
  local endWorldPos = Vec2.new(4 * constants.pixelSize, 4 * constants.pixelSize) -- (4,4)

  local result = pathFinder:findPath(startWorldPos, endWorldPos)
  luaunit.assertNil(result, "Should return nil when start position is out of bounds")
end

function TestPathFinder:testInvalidInput()
  setupMockMapManager()

  local pathFinder = PathFinder.new()

  -- Test with invalid positions (nil values)
  local result = pathFinder:findPath(nil, Vec2.new(1, 1))
  luaunit.assertNil(result, "Should return nil when start position is nil")

  local result2 = pathFinder:findPath(Vec2.new(1, 1), nil)
  luaunit.assertNil(result2, "Should return nil when end position is nil")
end

function TestPathFinder:testFunctionExists()
  setupMockMapManager()

  local pathFinder = PathFinder.new()

  -- Verify that findPath function exists and is callable
  luaunit.assertNotNil(pathFinder.findPath, "findPath function should exist")
  luaunit.assertTrue(type(pathFinder.findPath) == "function", "findPath should be a function")
end

-- Run the tests
luaunit.LuaUnit.run()

