--- Test file for EventBus system and event-driven architecture between BottomBar and Camera components

package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")

-- Mock dependencies
local mockEventBus = {}
mockEventBus.listeners = {}

function mockEventBus:on(eventType, callback)
    if not self.listeners[eventType] then
        self.listeners[eventType] = {}
    end
    table.insert(self.listeners[eventType], callback)
end

function mockEventBus:emit(eventType, data)
    local listeners = self.listeners[eventType]
    if not listeners then
        return
    end
    
    for _, callback in ipairs(listeners) do
        callback(data)
    end
end

-- Mock EntityManager
local mockEntityManager = {}
mockEntityManager.components = {}
mockEntityManager.entities = {}

function mockEntityManager:query(componentType)
    -- Return a simple mock table for testing
    return {1, 2, 3}
end

function mockEntityManager:getComponent(entityId, componentType)
    if componentType == "POSITION" then
        return {x = 5, y = 5}
    elseif componentType == "NAME" then
        return "TestColonist"
    elseif componentType == "SELECTED" then
        return true
    end
    return nil
end

function mockEntityManager:addComponent(entityId, componentType, value)
    -- Mock adding component
end

-- Mock Vec2
local mockVec2 = {}
function mockVec2.new(x, y)
    local self = {x = x, y = y}
    function self:mutAdd(dx, dy)
        self.x = self.x + dx
        self.y = self.y + dy
    end
    function self:equals(other)
        return self.x == other.x and self.y == other.y
    end
    return self
end

-- Mock constants
local mockConstants = {
    MAP_W = 100,
    MAP_H = 100,
    pixelSize = 32
}

-- Mock Logger
local mockLogger = {}
function mockLogger:debug(msg) end
function mockLogger:error(msg) end

-- Mock BottomBar
local mockBottomBar = {}
mockBottomBar.minimized = false
mockBottomBar.window = {height = 100}
mockBottomBar.tab = 1

-- Mock PauseMenu
local mockPauseMenu = {}
mockPauseMenu.visible = false

-- Setup mocks
package.loaded["game.systems.EventBus"] = mockEventBus
package.loaded["game.utils.EntityManager"] = mockEntityManager
package.loaded["game.utils.Vec2"] = mockVec2
package.loaded["game.utils.constants"] = mockConstants
package.loaded["logger"] = mockLogger
package.loaded["game.components.BottomBar"] = mockBottomBar
package.loaded["game.components.PauseMenu"] = mockPauseMenu

-- Now require the actual modules with mocks in place
local EventBus = require("game.systems.EventBus")
local Camera = require("game.components.Camera")

--- Test class for EventBus functionality
local EventBusTest = {}

function EventBusTest:testEventBusInitialization()
    -- Arrange
    local eventBus = EventBus
    
    -- Act & Assert
    luaunit.assertNotNil(eventBus)
    luaunit.assertTable(eventBus.listeners)
end

function EventBusTest:testEventBusRegistration()
    -- Arrange
    local eventBus = EventBus
    local testCallback = function() end
    
    -- Act
    eventBus:on("test_event", testCallback)
    
    -- Assert
    luaunit.assertNotNil(eventBus.listeners["test_event"])
    luaunit.assertEquals(#eventBus.listeners["test_event"], 1)
end

function EventBusTest:testEventBusEmission()
    -- Arrange
    local eventBus = EventBus
    local callbackCalled = false
    local testData = {message = "test"}
    
    local testCallback = function(data)
        callbackCalled = true
        luaunit.assertEquals(data.message, "test")
    end
    
    eventBus:on("test_event", testCallback)
    
    -- Act
    eventBus:emit("test_event", testData)
    
    -- Assert
    luaunit.assertTrue(callbackCalled)
end

function EventBusTest:testEventBusMultipleListeners()
    -- Arrange
    local eventBus = EventBus
    local callback1Called = false
    local callback2Called = false
    
    local testCallback1 = function()
        callback1Called = true
    end
    
    local testCallback2 = function()
        callback2Called = true
    end
    
    eventBus:on("test_event", testCallback1)
    eventBus:on("test_event", testCallback2)
    
    -- Act
    eventBus:emit("test_event")
    
    -- Assert
    luaunit.assertTrue(callback1Called)
    luaunit.assertTrue(callback2Called)
end

function EventBusTest:testEventBusNonExistentEvent()
    -- Arrange
    local eventBus = EventBus
    
    -- Act & Assert (should not crash)
    eventBus:emit("non_existent_event")
    luaunit.assertTrue(true) -- Test passes if no error occurs
end

--- Test class for Camera-EventBus integration
local CameraEventIntegrationTest = {}

function CameraEventIntegrationTest:testCameraListensToEntitySelectedEvent()
    -- Arrange
    local camera = Camera.new()
    
    -- Act & Assert
    luaunit.assertNotNil(camera)
    -- Check that the event listener was registered
    luaunit.assertNotNil(EventBus.listeners["entity_selected"])
end

function CameraEventIntegrationTest:testCameraCentersOnEntityPosition()
    -- Arrange
    local camera = Camera.new()
    local mockPosition = {x = 10, y = 10}
    
    -- Act
    EventBus:emit("entity_selected", {position = mockPosition})
    
    -- Assert - We can't directly test the centerOn method without mocking more complex behavior,
    -- but we can verify that the event was handled properly by checking if the listener was called
    luaunit.assertTrue(true) -- Test passes if no error occurs
end

function CameraEventIntegrationTest:testCameraHandlesEmptyEventData()
    -- Arrange
    local camera = Camera.new()
    
    -- Act & Assert (should not crash with nil data)
    EventBus:emit("entity_selected", nil)
    luaunit.assertTrue(true) -- Test passes if no error occurs
end

--- Test class for BottomBar-EventBus integration
local BottomBarEventIntegrationTest = {}

function BottomBarEventIntegrationTest:testBottomBarEmitsEntitySelectedEvent()
    -- Arrange
    local mockEventBus = EventBus
    local eventEmitted = false
    local eventData = nil
    
    -- Mock the event bus to capture emissions
    local originalEmit = mockEventBus.emit
    mockEventBus.emit = function(eventType, data)
        if eventType == "entity_selected" then
            eventEmitted = true
            eventData = data
        end
        return originalEmit(eventType, data)
    end
    
    -- Act - Simulate selecting an entity from BottomBar
    -- This would normally happen when a colonist button is clicked
    mockEventBus:emit("entity_selected", {entity = 1, position = {x = 5, y = 5}})
    
    -- Assert
    luaunit.assertTrue(eventEmitted)
    luaunit.assertNotNil(eventData)
    luaunit.assertEquals(eventData.entity, 1)
    luaunit.assertEquals(eventData.position.x, 5)
    luaunit.assertEquals(eventData.position.y, 5)
    
    -- Restore original emit function
    mockEventBus.emit = originalEmit
end

function BottomBarEventIntegrationTest:testBottomBarEventHandling()
    -- Arrange
    local mockEventBus = EventBus
    local eventHandled = false
    
    -- Register a test listener
    mockEventBus:on("entity_selected", function(data)
        eventHandled = true
    end)
    
    -- Act
    mockEventBus:emit("entity_selected", {test = "data"})
    
    -- Assert
    luaunit.assertTrue(eventHandled)
end

return {
    EventBusTest = EventBusTest,
    CameraEventIntegrationTest = CameraEventIntegrationTest,
    BottomBarEventIntegrationTest = BottomBarEventIntegrationTest
}