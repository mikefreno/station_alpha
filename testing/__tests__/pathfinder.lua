package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
Logger = require("logger")
local Vec2 = require("utils.Vec2")
local PathFinder = require("systems.PathFinder")
local MapManager = require("systems.MapManager")
local EntityManager = require("systems.EntityManager")
local constants = require("utils.constants")

local function createMockMapManager(width, height)
  local mapManager = MapManager.new(width, height)
  mapManager:createLevelMap()
  return mapManager
end

-- Test case for PathFinder
TestPathFinder = {}

function TestPathFinder:testEdgeCase()
  local mapManager = createMockMapManager(5, 5)

  -- Out of bounds start position
  local startWorldPos = Vec2.new(-1 * constants.pixelSize, -1 * constants.pixelSize) -- (-1,-1)
  local endWorldPos = Vec2.new(4 * constants.pixelSize, 4 * constants.pixelSize) -- (4,4)

  local pathFinder = PathFinder.new()
  local path = pathFinder:findPath(startWorldPos, endWorldPos, mapManager)

  luaunit.assertNil(path, "Expected no path found due to out of bounds start position")
end

function TestPathFinder:testNoPathAvailable()
  local mapManager = createMockMapManager(5, 5)

  -- Block the path
  mapManager.graph[2][2].style = require("utils.enums").TopographyType.INACCESSIBLE
  mapManager.graph[2][2].speedMultiplier = 0

  local startWorldPos = Vec2.new(1 * constants.pixelSize, 1 * constants.pixelSize) -- (1,1)
  local endWorldPos = Vec2.new(4 * constants.pixelSize, 4 * constants.pixelSize) -- (4,4)

  local pathFinder = PathFinder.new()
  local path = pathFinder:findPath(startWorldPos, endWorldPos, mapManager)

  luaunit.assertNil(path, "Expected no path to be found due to blockage")
end

function TestPathFinder:testSingleStepPath()
  local mapManager = createMockMapManager(5, 5)

  local startWorldPos = Vec2.new(1 * constants.pixelSize, 1 * constants.pixelSize) -- (1,1)
  local endWorldPos = Vec2.new(2 * constants.pixelSize, 1 * constants.pixelSize) -- (1,2)

  local pathFinder = PathFinder.new()
  local path = pathFinder:findPath(startWorldPos, endWorldPos, mapManager)

  local expectedPath = {
    Vec2.new(1 * constants.pixelSize, 1 * constants.pixelSize),
    Vec2.new(2 * constants.pixelSize, 1 * constants.pixelSize),
  }

  luaunit.assertEquals(#path, #expectedPath, "Path length does not match for single step")
  for i, v in ipairs(path) do
    luaunit.assertEquals(v.x, expectedPath[i].x, "X position does not match at index " .. i)
    luaunit.assertEquals(v.y, expectedPath[i].y, "Y position does not match at index " .. i)
  end
end

function TestPathFinder:testMultiplePaths()
  local mapManager = createMockMapManager(5, 5)

  -- Setup a map with multiple paths
  mapManager.graph[2][2].style = require("utils.enums").TopographyType.INACCESSIBLE
  mapManager.graph[2][3].style = require("utils.enums").TopographyType.INACCESSIBLE

  local startWorldPos = Vec2.new(1 * constants.pixelSize, 1 * constants.pixelSize) -- (1,1)
  local endWorldPos = Vec2.new(4 * constants.pixelSize, 4 * constants.pixelSize) -- (4,4)

  local pathFinder = PathFinder.new()
  local path = pathFinder:findPath(startWorldPos, endWorldPos, mapManager)

  luaunit.assertNotNil(path, "Expected a path to be found")
  luaunit.assertNotEquals(#path, 0, "Expected path length to be greater than 0")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
