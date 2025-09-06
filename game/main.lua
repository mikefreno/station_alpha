local enums = require("utils.enums")
local MapManager = require("systems.MapManager")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TaskType = enums.TaskType
local EntityManager = require("systems.EntityManager")
local InputSystem = require("systems.Input")
local PositionSystem = require("systems.Position")
local RenderSystem = require("systems.Render")
local Camera = require("components.Camera")
local Vec2 = require("utils.Vec2")
local Texture = require("components.Texture")
local Shape = require("components.Shape")
local pathfinder = require("systems.PathFinder")
local constants = require("utils.constants")
local LoadingIndicator = require("components.LoadingIndicator")
local TaskQueue = require("components.TaskQueue")
local overlayStats = require("libs.OverlayStats")
Logger = require("logger"):init()

local mapManager

local function isLoading()
    if not mapManager.graph or mapManager.dirtyGraph == true then
        return true
    end
end

function love.load()
    Camera = Camera.new()
    mapManager = MapManager.new(EntityManager, constants.MAP_W, constants.MAP_H)
    mapManager:createLevelMap()

    ---temporary for demoing purposes---
    Dot = EntityManager:createEntity()
    EntityManager:addComponent(Dot, ComponentType.POSITION, Vec2.new(1, 1))
    EntityManager:addComponent(Dot, ComponentType.VELOCITY, Vec2.new())
    EntityManager:addComponent(
        Dot,
        ComponentType.TEXTURE,
        Texture.new({ r = 1, g = 0.5, b = 0 })
    )
    EntityManager:addComponent(Dot, ComponentType.SHAPE, Shape.new(ShapeType.CIRCLE, 10))
    EntityManager:addComponent(Dot, ComponentType.TASKQUEUE, TaskQueue.new(Dot))
    ---temporary for demoing purposes---

    overlayStats.load()
end

local lastPos
function love.update(dt)
    MapManager:update()
    --InputSystem:update(EntityManager)
    PositionSystem:update(dt, EntityManager)
    Camera:update(dt)

    if isLoading() == true and LoadingIndicator.isVisible == false then
        LoadingIndicator:show()
    elseif isLoading() == false and LoadingIndicator.isVisible == true then
        LoadingIndicator:hide()
    end

    if LoadingIndicator.isVisible then
        LoadingIndicator:update(dt)
    end

    for e, _ in pairs(EntityManager.entities) do
        local tq = EntityManager:getComponent(e, ComponentType.TASKQUEUE)
        if tq then
            tq:update(dt, EntityManager)
        end
    end

    overlayStats.update(dt)
end

function love.keypressed(key, scancode, isrepeat)
    Logger:keypressed(key, scancode)
    overlayStats.handleKeyboard(key)
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        local sx, sy = x, y

        local worldX = (sx / Camera.zoom) + (Camera.position.x * constants.pixelSize)
        local worldY = (sy / Camera.zoom) + (Camera.position.y * constants.pixelSize)

        -- Convert pixel world to grid indices
        local clickGrid = mapManager:worldToGrid(Vec2.new(worldX, worldY))
        local DotPos = EntityManager:getComponent(Dot, ComponentType.POSITION)

        Logger:debug(DotPos)
        Logger:debug(clickGrid)

        -- Current dot position stored as logical grid coords
        local currentDotPos = EntityManager:getComponent(Dot, ComponentType.POSITION)

        local path = pathfinder:findPath(currentDotPos, clickGrid, mapManager)
        if path == nil then
            return
        end

        if path and #path > 0 then
            local taskQueue = EntityManager:getComponent(Dot, ComponentType.TASKQUEUE)
            if taskQueue then
                for _, wp in ipairs(path) do
                    taskQueue:push({ type = TaskType.MOVETO, data = Vec2.new(wp.x, wp.y) })
                end
            end
        end
    end
end

function love.wheelmoved(x, y)
    if love.keyboard.isDown("lctrl") then
        Logger:wheelmoved(x, y)
    else
        Camera:wheelmoved(x, y)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    overlayStats.handleTouch(id, x, y, dx, dy, pressure)
end

function love.draw()
    Camera:apply()
    RenderSystem:update(EntityManager)
    Camera:unapply()
    LoadingIndicator:draw()
    Logger:draw()
    overlayStats.draw()
end
