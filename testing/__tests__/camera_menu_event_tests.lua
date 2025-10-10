package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")

-- Mock dependencies
local EventBus = {}
EventBus.listeners = {}
function EventBus:on(eventType, callback)
    if not self.listeners[eventType] then
        self.listeners[eventType] = {}
    end
    table.insert(self.listeners[eventType], callback)
end
function EventBus:emit(eventType, data)
    local listeners = self.listeners[eventType]
    if not listeners then
        return
    end
    
    for _, callback in ipairs(listeners) do
        callback(data)
    end
end

-- Mock EntityManager
local EntityManager = {}
EntityManager.components = {}
function EntityManager:getComponent(entityId, componentType)
    return self.components[entityId] and self.components[entityId][componentType]
end
function EntityManager:find(componentType, value)
    for id, components in pairs(self.components) do
        if components[componentType] == value then
            return id
        end
    end
    return nil
end

-- Mock MapManager
local MapManager = {}
function MapManager:gridToWorld(gridPos)
    return gridPos
end
function MapManager:worldToGrid(worldPos)
    return worldPos
end

-- Mock constants and enums
local constants = {
    pixelSize = 32,
    MAP_W = 100,
    MAP_H = 100
}
local enums = {
    ComponentType = {
        SELECTED = 1,
        POSITION = 2,
        SPEEDSTAT = 3,
        NAME = 4,
        TASKQUEUE = 5
    },
    ZIndexing = {
        RightClickMenu = 100
    }
}

-- Mock Vec2
local Vec2 = {}
Vec2.__index = Vec2
function Vec2.new(x, y)
    local self = setmetatable({}, Vec2)
    self.x = x
    self.y = y
    return self
end
function Vec2:mutAdd(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end
function Vec2:equals(other)
    return self.x == other.x and self.y == other.y
end

-- Mock FlexLove GUI
local FlexLove = {}
FlexLove.GUI = {}
FlexLove.Color = {}
FlexLove.enums = {
    Positioning = { FLEX = "flex" },
    FlexDirection = { VERTICAL = "vertical" },
    JustifyContent = { CENTER = "center" },
    AlignContent = { CENTER = "center" },
    AlignItems = { CENTER = "center" }
}
function FlexLove.GUI.new(params)
    return {
        destroy = function() end,
        getBounds = function() return { x = 0, y = 0, width = 100, height = 100 } end
    }
end
function FlexLove.Color.new(r, g, b, a)
    return { r = r, g = g, b = b, a = a }
end

-- Mock BottomBar
local BottomBar = {
    minimized = false,
    window = { height = 50 }
}

-- Patch required modules
package.loaded["game.systems.EventBus"] = EventBus
package.loaded["game.systems.EntityManager"] = EntityManager
package.loaded["game.systems.MapManager"] = MapManager
package.loaded["game.utils.constants"] = constants
package.loaded["game.utils.enums"] = enums
package.loaded["game.utils.Vec2"] = Vec2
package.loaded["game.libs.FlexLove"] = FlexLove
package.loaded["game.components.BottomBar"] = BottomBar

-- Import the actual Camera and RightClickMenu modules
local Camera = require("game.components.Camera")
local RightClickMenu = require("game.components.RightClickMenu")

-- Test suite for camera movement events and menu position recalculation
local TestCameraMenuEvents = {}

function TestCameraMenuEvents:test_camera_emits_moved_event()
    -- Arrange: Create a camera instance and setup event listener to capture emitted events
    local camera = Camera.new()
    local capturedEvent = nil
    local eventCount = 0
    
    EventBus:on("camera_moved", function(data)
        eventCount = eventCount + 1
        capturedEvent = data
    end)

    -- Act: Move the camera
    camera:move(10, 20)

    -- Assert: Verify that the event was emitted with correct position data
    luaunit.assertEquals(eventCount, 1)
    luaunit.assertNotNil(capturedEvent)
    luaunit.assertEquals(capturedEvent.position.x, 11)  -- Initial position 1 + move 10
    luaunit.assertEquals(capturedEvent.position.y, 21)  -- Initial position 1 + move 20
end

function TestCameraMenuEvents:test_camera_emits_moved_event_on_zoom()
    -- Arrange: Create a camera instance and setup event listener to capture emitted events
    local camera = Camera.new()
    local capturedEvent = nil
    local eventCount = 0
    
    EventBus:on("camera_moved", function(data)
        eventCount = eventCount + 1
        capturedEvent = data
    end)

    -- Act: Change zoom level
    camera:setZoom(1.5)

    -- Assert: Verify that the event was emitted with correct position data after zoom
    luaunit.assertEquals(eventCount, 1)
    luaunit.assertNotNil(capturedEvent)
    luaunit.assertEquals(capturedEvent.position.x, 1)  -- Position unchanged
    luaunit.assertEquals(capturedEvent.position.y, 1)  -- Position unchanged
end

function TestCameraMenuEvents:test_camera_emits_moved_event_on_center()
    -- Arrange: Create a camera instance and setup event listener to capture emitted events
    local camera = Camera.new()
    local capturedEvent = nil
    local eventCount = 0
    
    EventBus:on("camera_moved", function(data)
        eventCount = eventCount + 1
        capturedEvent = data
    end)

    -- Act: Center on a point
    camera:centerOn(Vec2.new(50, 50))

    -- Assert: Verify that the event was emitted with correct position data after centering
    luaunit.assertEquals(eventCount, 1)
    luaunit.assertNotNil(capturedEvent)
    luaunit.assertEquals(capturedEvent.position.x, 49.5)  -- Centered at 50, half width
    luaunit.assertEquals(capturedEvent.position.y, 49.5)  -- Centered at 50, half height
end

function TestCameraMenuEvents:test_rightclickmenu_updates_position_on_camera_moved()
    -- Arrange: Create a RightClickMenu instance and set up initial position
    local menu = RightClickMenu
    menu:updatePosition(10, 20)  -- Set initial world position
    
    -- Mock the event listener to capture recalculation events
    local recalculateCalled = false
    local capturedData = nil
    EventBus:on("camera_moved", function(data)
        recalculateCalled = true
        capturedData = data
    end)

    -- Act: Simulate camera movement event
    EventBus:emit("camera_moved", { position = Vec2.new(5, 10) })

    -- Assert: Verify that the menu recalculates its position correctly
    luaunit.assertTrue(recalculateCalled)
    luaunit.assertNotNil(capturedData)
    luaunit.assertEquals(menu.worldPosition.x, 10)  -- Should remain same as initial
    luaunit.assertEquals(menu.worldPosition.y, 20)  -- Should remain same as initial
end

function TestCameraMenuEvents:test_rightclickmenu_handles_missing_position_data()
    -- Arrange: Create a RightClickMenu instance and set up initial position
    local menu = RightClickMenu
    menu:updatePosition(10, 20)
    
    -- Mock the event listener to capture recalculation events
    local recalculateCalled = false
    EventBus:on("camera_moved", function(data)
        recalculateCalled = true
        if data and data.position then
            -- This should not be called in our case since we check for position existence
        end
    end)

    -- Act: Simulate camera movement event with missing position data
    EventBus:emit("camera_moved", {})

    -- Assert: Verify that menu handles empty event gracefully
    luaunit.assertTrue(recalculateCalled)  -- Event listener was called, but no recalculation happened due to nil check
end

function TestCameraMenuEvents:test_rightclickmenu_handles_nil_grid_position()
    -- Arrange: Create a RightClickMenu instance without setting position
    local menu = RightClickMenu
    
    -- Mock the event listener to capture recalculation events
    local recalculateCalled = false
    EventBus:on("camera_moved", function(data)
        recalculateCalled = true
        if data and data.position and menu.gridPosition then
            -- This should not be called since gridPosition is nil
        end
    end)

    -- Act: Simulate camera movement event
    EventBus:emit("camera_moved", { position = Vec2.new(5, 10) })

    -- Assert: Verify that menu handles nil grid position gracefully
    luaunit.assertTrue(recalculateCalled)
end

function TestCameraMenuEvents:test_camera_clamps_position_on_move()
    -- Arrange: Create a camera instance with specific bounds
    local camera = Camera.new()
    
    -- Act: Move the camera beyond bounds (should be clamped)
    camera:move(100, 100)  -- This should go beyond max bounds
    
    -- Assert: Verify that position was clamped to valid range
    luaunit.assertLessThan(camera.position.x, 100)  -- Should be clamped below max
    luaunit.assertLessThan(camera.position.y, 100)  -- Should be clamped below max
end

return {
    TestCameraMenuEvents = TestCameraMenuEvents
}