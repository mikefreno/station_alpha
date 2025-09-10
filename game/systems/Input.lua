local ComponentType = require("utils.enums").ComponentType
local EntityManager = require("systems.EntityManager")
local Vec2 = require("utils.Vec2")

local InputSystem = {}
InputSystem.__index = InputSystem

function InputSystem.new()
    local self = setmetatable({}, InputSystem)
    return self
end

---@param entityManager EntityManager
function InputSystem:update(entityManager) end

function InputSystem:keypressed(key, scancode, isrepeat)
    -- Handle keyboard input here if needed
end

---comment
---@param x number
---@param y number
---@param button integer
---@param istouch boolean
---@param entityManager EntityManager
function InputSystem:handleMousePressed(x, y, button, istouch, entityManager)
    if button == 1 then
        -- Find entities at the click position that are not map tiles
        local entities = entityManager:query(ComponentType.POSITION)
        for _, entityId in ipairs(entities) do
            -- Skip map tile entities
            if entityManager:getComponent(entityId, ComponentType.MAPTILETAG) == nil then
                local bounds = entityManager:getEntityBounds(entityId)
                if bounds then
                    -- Check if click position is within entity bounds
                    if
                        x >= bounds.x
                        and x <= bounds.x + bounds.width
                        and y >= bounds.y
                        and y <= bounds.y + bounds.height
                    then
                        Logger:debug("Entity " .. entityId .. " clicked at position (" .. x .. ", " .. y .. ")")
                        break
                    end
                end
            end
        end
        local rcm = EntityManager:getComponent(1, ComponentType.RIGHTCLICKMENU)
        if not rcm.hovered then rcm:hide() end
    elseif button == 2 then
        local rcm = EntityManager:getComponent(1, ComponentType.RIGHTCLICKMENU)
        if rcm and not rcm.position then rcm.position = Vec2.new() end
        if rcm then
            Logger:debug("Setting RCM position to: x=" .. tostring(x) .. ", y=" .. tostring(y))
            rcm.position.x = x
            rcm.position.y = y
            rcm.showing = true
        else
            Logger:error("No RCM found")
        end
    end
end

function InputSystem:handleWheelMoved(x, y)
    local rcm = EntityManager:getComponent(1, ComponentType.RIGHTCLICKMENU)
    if rcm.showing then
    else
        local camera = EntityManager:getComponent(1, ComponentType.CAMERA)
        camera:wheelmoved(x, y)
    end
end

return InputSystem.new()
