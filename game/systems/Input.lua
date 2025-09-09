local ComponentType = require("utils.enums").ComponentType
local EntityManager = require("systems.EntityManager")
local Vec2 = require("utils.Vec2")
local pathfinder = require("systems.PathFinder")
local constants = require("utils.constants")

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
---@param mapManager MapManager
function InputSystem:handleMousePressed(x, y, button, istouch, entityManager, mapManager)
    if button == 1 then
        local camera = EntityManager:getComponent(1, ComponentType.CAMERA)
        local taskManager = EntityManager:getComponent(1, ComponentType.TASKMANAGER)

        local worldX = (x / camera.zoom) + (camera.position.x * constants.pixelSize)
        local worldY = (y / camera.zoom) + (camera.position.y * constants.pixelSize)

        -- Convert pixel world to grid indices
        local clickGrid = mapManager:worldToGrid(Vec2.new(worldX, worldY))

        -- Current dot position stored as logical grid coords
        local currentDotPos = EntityManager:getComponent(Dot, ComponentType.POSITION)
        local dotShape = EntityManager:getComponent(Dot, ComponentType.SHAPE)

        local path = pathfinder:findPath(currentDotPos:add(dotShape.size / 2, dotShape.size / 2), clickGrid, mapManager)
        if path == nil then return end

        taskManager:newPath(Dot, path)
        local rcm = EntityManager:getComponent(1, ComponentType.RIGHTCLICKMENU)
        rcm:hide()
    elseif button == 2 then
        local rcm = EntityManager:getComponent(1, ComponentType.RIGHTCLICKMENU)
        if rcm and not rcm.position then rcm.position = Vec2.new() end
        if rcm then
            rcm.position.x = x
            rcm.position.y = y
            rcm.showing = true
        else
            Logger:error("No RCM found")
        end
    end
end

function InputSystem:handleWheelMoved(x, y)
    -- Wheel movement handling would go here
end

return InputSystem.new()
