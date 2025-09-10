local enums = require("game.utils.enums")
local MapManager = require("game.systems.MapManager")
local Schedule = require("game.components.Schedule")
local RightClickMenu = require("game.components.RightClickMenu")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TaskType = enums.TaskType
local EntityManager = require("game.systems.EntityManager")
local InputSystem = require("game.systems.Input")
local PositionSystem = require("game.systems.Position")
local RenderSystem = require("game.systems.Render")
local TaskManager = require("game.systems.TaskManager")
local Camera = require("game.components.Camera")
local Vec2 = require("game.utils.Vec2")
local Texture = require("game.components.Texture")
local Shape = require("game.components.Shape")
local Pathfinder = require("game.systems.PathFinder")
local constants = require("game.utils.constants")
local LoadingIndicator = require("game.components.LoadingIndicator")
local TaskQueue = require("game.components.TaskQueue")
local overlayStats = require("game.libs.OverlayStats")
Logger = require("game.logger"):init()
local Slab = require("libs.Slab")

local function isLoading()
    if not mapManager.graph or mapManager.dirtyGraph == true then return true end
end

local function initGod()
    EntityManager:addComponent(EntityManager.god, ComponentType.CAMERA, Camera.new())
    mapManager = MapManager.new(EntityManager, constants.MAP_W, constants.MAP_H)
    EntityManager:addComponent(EntityManager.god, ComponentType.MAPMANAGER, mapManager)
    mapManager:createLevelMap()
    EntityManager:addComponent(
        EntityManager.god,
        ComponentType.TASKMANAGER,
        TaskManager.init(EntityManager, mapManager)
    )
    EntityManager:addComponent(EntityManager.god, ComponentType.RIGHTCLICKMENU, RightClickMenu.new())
    EntityManager:addComponent(EntityManager.god, ComponentType.PATHFINDER, Pathfinder.new())
end

---NOTE: temporary for demoing purposes---
local function initDot()
    EntityManager:addComponent(EntityManager.dot, ComponentType.POSITION, Vec2.new(1, 1))
    EntityManager:addComponent(EntityManager.dot, ComponentType.VELOCITY, Vec2.new())
    -- 100 meters(50 tiles) in 70 seconds
    EntityManager:addComponent(EntityManager.dot, ComponentType.SPEEDSTAT, 50 / 70)
    EntityManager:addComponent(EntityManager.dot, ComponentType.TEXTURE, Texture.new({ r = 1, g = 0.5, b = 0 }))
    EntityManager:addComponent(EntityManager.dot, ComponentType.SHAPE, Shape.new(ShapeType.CIRCLE, 0.75))
    EntityManager:addComponent(EntityManager.dot, ComponentType.TASKQUEUE, TaskQueue.new(Dot))
    EntityManager:addComponent(EntityManager.dot, ComponentType.SCHEDULE, Schedule.new())
end

function love.load(args)
    initGod()
    initDot()
    Slab.Initialize(args)
    overlayStats.load()
end

function love.update(dt)
    local camera = EntityManager:getComponent(1, ComponentType.CAMERA)
    local taskManager = EntityManager:getComponent(1, ComponentType.TASKMANAGER)
    camera:update(dt)
    PositionSystem:update(dt, EntityManager)
    mapManager:update()
    InputSystem:update(EntityManager)
    taskManager:update(dt)

    Slab.Update(dt)

    if isLoading() == true and LoadingIndicator.isVisible == false then
        LoadingIndicator:show()
    elseif isLoading() == false and LoadingIndicator.isVisible == true then
        LoadingIndicator:hide()
    end

    if LoadingIndicator.isVisible then LoadingIndicator:update(dt) end

    overlayStats.update(dt)
end

function love.keypressed(key, scancode, isrepeat)
    Logger:keypressed(key, scancode)
    overlayStats.handleKeyboard(key)
    -- Forward keypress to input system if needed
    InputSystem:keypressed(key, scancode, isrepeat)
end

function love.mousepressed(x, y, button, istouch) InputSystem:handleMousePressed(x, y, button, istouch, EntityManager) end

function love.wheelmoved(x, y)
    if love.keyboard.isDown("lctrl") then
        Logger:wheelmoved(x, y)
    else
        InputSystem:handleWheelMoved(x, y)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure) overlayStats.handleTouch(id, x, y, dx, dy, pressure) end

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
