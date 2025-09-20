package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
Logger = require("logger")

-- Mock love functions
love = {
  window = {
    getMode = function() return 800, 600 end
  },
  mouse = {
    getPosition = function() return 400, 300 end
  },
  keyboard = {
    isDown = function(key) return false end
  },
  timer = {
    getTime = function() return 10.0 end
  }
}

-- Mock BottomBar component
BottomBar = {
  window = {
    height = 60 -- 10% of 600px
  },
  minimized = false
}

-- Mock EntityManager
EntityManager = {
  entities = {},
  components = {},
  getComponent = function(self, entityId, componentType)
    if self.components[componentType] then
      return self.components[componentType][entityId]
    end
    return nil
  end
}

-- Mock PauseMenu
PauseMenu = {
  visible = false
}

local Camera = require("game.components.Camera")
local Vec2 = require("game.utils.Vec2")

TestCameraPanning = {}

function TestCameraPanning:setUp()
  -- Reset the BottomBar state
  BottomBar.minimized = false
  BottomBar.window.height = 60
  
  -- Reset love mouse position
  love.mouse.getPosition = function() return 400, 300 end
  
  -- Reset camera to default state
  Camera.panningZoneBuffer = 0.2
end

function TestCameraPanning:test_panning_when_bottombar_maximized()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = false
  
  -- Mock mouse position near top edge (should trigger panning)
  love.mouse.getPosition = function() return 400, 50 end -- 50px from top edge
  
  -- Act
  camera:update(0.016) -- 16ms delta time
  
  -- Assert
  -- Camera should have moved up (negative y direction)
  luaunit.assertLessThan(camera.position.y, 10) -- Position should decrease
end

function TestCameraPanning:test_panning_when_bottombar_minimized()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = true
  
  -- Mock mouse position near bottom edge (should trigger panning)
  love.mouse.getPosition = function() return 400, 550 end -- 50px from bottom edge
  
  -- Act
  camera:update(0.016) -- 16ms delta time
  
  -- Assert
  -- Camera should have moved down (positive y direction)
  luaunit.assertGreaterThan(camera.position.y, 10) -- Position should increase
end

function TestCameraPanning:test_panning_zone_buffer_logic_maximized()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = false
  
  -- Mock mouse position near bottom edge (should trigger panning but buffer prevents it initially)
  love.mouse.getPosition = function() return 400, 550 end -- 50px from bottom edge
  
  -- Set buffer to prevent immediate panning
  camera.panningZoneBuffer = 0.3 -- Longer buffer than dt
  
  -- Act - first update with buffer active
  camera:update(0.016) -- 16ms delta time
  
  -- Assert - should not have moved because of buffer
  luaunit.assertEquals(camera.position.y, 10) -- Position should remain unchanged
  
  -- Act - second update after buffer expires
  camera:update(0.016) -- 16ms delta time
  
  -- Assert - should have moved now that buffer is expired
  luaunit.assertGreaterThan(camera.position.y, 10) -- Position should increase
end

function TestCameraPanning:test_panning_zone_buffer_logic_minimized()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = true
  
  -- Mock mouse position near bottom edge (should trigger panning but buffer prevents it initially)
  love.mouse.getPosition = function() return 400, 550 end -- 50px from bottom edge
  
  -- Set buffer to prevent immediate panning
  camera.panningZoneBuffer = 0.3 -- Longer buffer than dt
  
  -- Act - first update with buffer active
  camera:update(0.016) -- 16ms delta time
  
  -- Assert - should not have moved because of buffer
  luaunit.assertEquals(camera.position.y, 10) -- Position should remain unchanged
  
  -- Act - second update after buffer expires
  camera:update(0.016) -- 16ms delta time
  
  -- Assert - should have moved now that buffer is expired
  luaunit.assertGreaterThan(camera.position.y, 10) -- Position should increase
end

function TestCameraPanning:test_mouse_over_bottom_bar_returns_early()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = false
  
  -- Mock mouse position over bottom bar (should return early without panning)
  love.mouse.getPosition = function() return 400, 580 end -- Over the bottom bar area
  
  -- Act
  camera:update(0.016) -- 16ms delta time
  
  -- Assert - should not have moved because mouse is over bottom bar
  luaunit.assertEquals(camera.position.y, 10) -- Position should remain unchanged
end

function TestCameraPanning:test_mouse_over_bottom_bar_minimized_returns_early()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = true
  
  -- Mock mouse position over bottom bar (should return early without panning)
  love.mouse.getPosition = function() return 400, 580 end -- Over the bottom bar area
  
  -- Act
  camera:update(0.016) -- 16ms delta time
  
  -- Assert - should not have moved because mouse is over bottom bar
  luaunit.assertEquals(camera.position.y, 10) -- Position should remain unchanged
end

function TestCameraPanning:test_panning_with_horizontal_movement_maximized()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = false
  
  -- Mock mouse position near left edge (should trigger horizontal panning)
  love.mouse.getPosition = function() return 50, 300 end -- 50px from left edge
  
  -- Act
  camera:update(0.016) -- 16ms delta time
  
  -- Assert
  -- Camera should have moved left (negative x direction)
  luaunit.assertLessThan(camera.position.x, 10) -- Position should decrease
end

function TestCameraPanning:test_panning_with_horizontal_movement_minimized()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = true
  
  -- Mock mouse position near right edge (should trigger horizontal panning)
  love.mouse.getPosition = function() return 750, 300 end -- 50px from right edge
  
  -- Act
  camera:update(0.016) -- 16ms delta time
  
  -- Assert
  -- Camera should have moved right (positive x direction)
  luaunit.assertGreaterThan(camera.position.x, 10) -- Position should increase
end

function TestCameraPanning:test_panning_reset_buffer_when_not_over_vertical_pad()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.panningBorder = 0.1
  BottomBar.minimized = false
  
  -- Set buffer to prevent immediate panning
  camera.panningZoneBuffer = 0.3 -- Longer buffer than dt
  
  -- Mock mouse position not near any edge (should reset buffer)
  love.mouse.getPosition = function() return 400, 300 end -- Middle of screen
  
  -- Act
  camera:update(0.016) -- 16ms delta time
  
  -- Assert - buffer should be reset to default
  luaunit.assertEquals(camera.panningZoneBuffer, 0.2) -- Should reset to default value
end

function TestCameraPanning:test_panning_with_zoom()
  -- Arrange
  local camera = Camera.new()
  camera.position = Vec2.new(10, 10)
  camera.zoom = 2.0
  camera.panningBorder = 0.1
  BottomBar.minimized = false
  
  -- Mock mouse position near top edge (should trigger panning)
  love.mouse.getPosition = function() return 400, 50 end -- 50px from top edge
  
  -- Act
  camera:update(0.016) -- 16ms delta time
  
  -- Assert
  -- Camera should have moved up (negative y direction)
  luaunit.assertLessThan(camera.position.y, 10) -- Position should decrease
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())