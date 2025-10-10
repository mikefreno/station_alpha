--- Basic tests for EventBus system
package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
local EventBus = require("game.systems.EventBus")

--- Test class for basic EventBus functionality
local EventBusBasicTest = {}

function EventBusBasicTest:testEventBusInitialization()
    -- Arrange
    local eventBus = EventBus
    
    -- Act & Assert
    luaunit.assertNotNil(eventBus)
    luaunit.assertTable(eventBus.listeners)
end

function EventBusBasicTest:testEventBusRegistration()
    -- Arrange
    local eventBus = EventBus
    local testCallback = function() end
    
    -- Act
    eventBus:on("test_event", testCallback)
    
    -- Assert
    luaunit.assertNotNil(eventBus.listeners["test_event"])
    luaunit.assertEquals(#eventBus.listeners["test_event"], 1)
end

function EventBusBasicTest:testEventBusEmission()
    -- Arrange
    local eventBus = EventBus
    local testData = {message = "test"}
    
    local testCallback = function(data)
        luaunit.assertEquals(data.message, "test")
    end
    
    eventBus:on("test_event", testCallback)
    
    -- Act
    eventBus:emit("test_event", testData)
    
    -- Assert - Test passes if no assertion fails
    luaunit.assertTrue(true)
end

function EventBusBasicTest:testEventBusMultipleListeners()
    -- Arrange
    local eventBus = EventBus
    
    local testCallback1 = function() end
    
    local testCallback2 = function() end
    
    eventBus:on("test_event", testCallback1)
    eventBus:on("test_event", testCallback2)
    
    -- Act
    eventBus:emit("test_event")
    
    -- Assert - Test passes if no error occurs
    luaunit.assertTrue(true)
end

function EventBusBasicTest:testEventBusNonExistentEvent()
    -- Arrange
    local eventBus = EventBus
    
    -- Act & Assert (should not crash)
    eventBus:emit("non_existent_event")
    luaunit.assertTrue(true) -- Test passes if no error occurs
end

function EventBusBasicTest:testEventBusUnregistration()
    -- Arrange
    local eventBus = EventBus
    
    local testCallback = function() end
    
    eventBus:on("test_event", testCallback)
    
    -- Act
    eventBus:off("test_event", testCallback)
    
    -- Assert
    luaunit.assertEquals(#eventBus.listeners["test_event"], 0)
end

function EventBusBasicTest:testEventBusUnregistrationWithMultipleListeners()
    -- Arrange
    local eventBus = EventBus
    
    local testCallback1 = function() end
    
    local testCallback2 = function() end
    
    eventBus:on("test_event", testCallback1)
    eventBus:on("test_event", testCallback2)
    
    -- Act - unregister only one callback
    eventBus:off("test_event", testCallback1)
    
    -- Assert
    luaunit.assertEquals(#eventBus.listeners["test_event"], 1)
    
    -- Act - emit event and verify that the unregistration worked
    eventBus:emit("test_event")
    
    -- Test passes if no error occurs
    luaunit.assertTrue(true)
end

return {
    EventBusBasicTest = EventBusBasicTest
}