---@class EventBus
--- Simple event broadcasting system for decoupling components
local EventBus = {}
EventBus.__index = EventBus

--- Event listeners table
EventBus.listeners = {}

--- Register a listener for an event type
---@param eventType string
---@param callback function
function EventBus:on(eventType, callback)
    if not self.listeners[eventType] then
        self.listeners[eventType] = {}
    end
    table.insert(self.listeners[eventType], callback)
end

--- Emit an event with optional data
---@param eventType string
---@param data any?
function EventBus:emit(eventType, data)
    local listeners = self.listeners[eventType]
    if not listeners then
        return
    end
    
    for _, callback in ipairs(listeners) do
        callback(data)
    end
end

return EventBus