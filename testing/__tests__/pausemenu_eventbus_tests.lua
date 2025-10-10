--- Test file for PauseMenu EventBus integration
package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
local EventBus = require("game.systems.EventBus")
local PauseMenu = require("game.components.PauseMenu")

--- Test class for PauseMenu EventBus integration
local PauseMenuEventIntegrationTest = {}

function PauseMenuEventIntegrationTest:testPauseMenuEmitGamePausedEvent()
    -- Arrange
    local eventEmitted = false
    local eventData = nil
    
    -- Mock the event bus to capture emissions
    local originalEmit = EventBus.emit
    EventBus.emit = function(eventType, data)
        if eventType == "game_paused" then
            eventEmitted = true
            eventData = data
        end
        return originalEmit(eventType, data)
    end
    
    -- Act - toggle pause menu
    PauseMenu:toggle()
    
    -- Assert
    luaunit.assertTrue(eventEmitted)
    luaunit.assertNotNil(eventData)
    luaunit.assertEquals(eventData.paused, true)
    
    -- Restore original emit function
    EventBus.emit = originalEmit
end

return {
    PauseMenuEventIntegrationTest = PauseMenuEventIntegrationTest
}