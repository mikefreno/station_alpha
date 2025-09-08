local enums = require("utils.enums")
local MapManager = require("systems.MapManager")
local Schedule = require("components.Schedule")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TaskType = enums.TaskType
local EntityManager = require("systems.EntityManager")
local InputSystem = require("systems.Input")
local PositionSystem = require("systems.Position")
local RenderSystem = require("systems.Render")
local TaskManager = require("systems.TaskManager")
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
local Slab = require("libs.Slab")

local mapManager

local function isLoading()
    if not mapManager.graph or mapManager.dirtyGraph == true then
        return true
    end
end

function love.load(args)
    God = EntityManager:createEntity() -- id 1
    EntityManager:addComponent(God, ComponentType.CAMERA, Camera.new())
    mapManager = MapManager.new(EntityManager, constants.MAP_W, constants.MAP_H)
    mapManager:createLevelMap()
    EntityManager:addComponent(God, ComponentType.TASKMANAGER, TaskManager.init(EntityManager, mapManager))

    ---temporary for demoing purposes---
    Dot = EntityManager:createEntity()
    EntityManager:addComponent(Dot, ComponentType.POSITION, Vec2.new(1, 1))
    EntityManager:addComponent(Dot, ComponentType.VELOCITY, Vec2.new())
    -- 100 meters(50 tiles) in 70 seconds
    EntityManager:addComponent(Dot, ComponentType.SPEEDSTAT, 50 / 70)
    EntityManager:addComponent(Dot, ComponentType.TEXTURE, Texture.new({ r = 1, g = 0.5, b = 0 }))
    EntityManager:addComponent(Dot, ComponentType.SHAPE, Shape.new(ShapeType.CIRCLE, 0.75))
    EntityManager:addComponent(Dot, ComponentType.TASKQUEUE, TaskQueue.new(Dot))
    EntityManager:addComponent(Dot, ComponentType.SCHEDULE, Schedule.new())
    ---temporary for demoing purposes---

    Slab.Initialize(args)
    overlayStats.load()
end

function love.update(dt)
    local camera = EntityManager:getComponent(1, ComponentType.CAMERA)
    local taskManager = EntityManager:getComponent(1, ComponentType.TASKMANAGER)
    camera:update(dt)
    PositionSystem:update(dt, EntityManager)
    mapManager:update()
    --InputSystem:update(EntityManager)
    taskManager:update(dt)

    Slab.Update(dt)

    if isLoading() == true and LoadingIndicator.isVisible == false then
        LoadingIndicator:show()
    elseif isLoading() == false and LoadingIndicator.isVisible == true then
        LoadingIndicator:hide()
    end

    if LoadingIndicator.isVisible then
        LoadingIndicator:update(dt)
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
        local camera = EntityManager:getComponent(1, ComponentType.CAMERA)
        local taskManager = EntityManager:getComponent(1, ComponentType.TASKMANAGER)

        local worldX = (sx / camera.zoom) + (camera.position.x * constants.pixelSize)
        local worldY = (sy / camera.zoom) + (camera.position.y * constants.pixelSize)

        -- Convert pixel world to grid indices
        local clickGrid = mapManager:worldToGrid(Vec2.new(worldX, worldY))

        -- Current dot position stored as logical grid coords
        local currentDotPos = EntityManager:getComponent(Dot, ComponentType.POSITION)
        local dotShape = EntityManager:getComponent(Dot, ComponentType.SHAPE)

        local path = pathfinder:findPath(currentDotPos:add(dotShape.size / 2, dotShape.size / 2), clickGrid, mapManager)
        if path == nil then
            return
        end

        taskManager:newPath(Dot, path)
    elseif button == 2 then
        Slab.BeginWindow("MyFirstWindow", { Title = "Dot Options" })
        Slab.Text("Hello World")
        Slab.EndWindow()
    end
end

function love.wheelmoved(x, y)
    if love.keyboard.isDown("lctrl") then
        Logger:wheelmoved(x, y)
    else
        local camera = EntityManager:getComponent(1, ComponentType.CAMERA)
        camera:wheelmoved(x, y)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    overlayStats.handleTouch(id, x, y, dx, dy, pressure)
end

function love.resize()
    local function recalcPixelSize()
        local width = love.window.getMode()
        constants.pixelSize = width / 40 -- fit 40 tiles in the width
    end

    recalcPixelSize()
end

function love.draw()
    local camera = EntityManager:getComponent(1, ComponentType.CAMERA)
    camera:apply()
    RenderSystem:update(EntityManager, camera:getVisibleBounds())
    camera:unapply()
    LoadingIndicator:draw()
    Slab.Draw()
    Logger:draw()
    overlayStats.draw()
end
