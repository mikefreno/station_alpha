local enums = require("game.utils.enums")
local mapManager = require("game.systems.MapManager")
local Schedule = require("game.components.Schedule")
local rightClickMenu = require("game.components.RightClickMenu")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TaskType = enums.TaskType
EntityManager = require("game.systems.EntityManager")
local InputSystem = require("game.systems.Input")
local PositionSystem = require("game.systems.Position")
local RenderSystem = require("game.systems.Render")
local taskManager = require("game.systems.TaskManager")
local camera = require("game.components.Camera")
local Vec2 = require("game.utils.Vec2")
local Texture = require("game.components.Texture")
local Shape = require("game.components.Shape")
local pathfinder = require("game.systems.PathFinder")
local constants = require("game.utils.constants")
local LoadingIndicator = require("game.components.LoadingIndicator")
local TaskQueue = require("game.components.TaskQueue")
local overlayStats = require("game.libs.OverlayStats")
Logger = require("game.logger"):init()
local Slab = require("libs.Slab")
local Gui = require("game.libs.MyGUI")

local function isLoading()
    if not MapManager.graph or MapManager.dirtyGraph == true then return true end
end

local function initSystems()
    Camera = camera.new()
    MapManager = mapManager.new(constants.MAP_W, constants.MAP_H)
    MapManager:createLevelMap()
    TaskManager = taskManager.new()
    RCM = rightClickMenu.new()
    Pathfinder = pathfinder.new()
end

---NOTE: temporary for demoing purposes---
local function initDot()
    EntityManager:addComponent(EntityManager.dot, ComponentType.POSITION, Vec2.new(1, 1))
    EntityManager:addComponent(EntityManager.dot, ComponentType.VELOCITY, Vec2.new())
    -- 100 meters(50 tiles) in 70 seconds
    EntityManager:addComponent(EntityManager.dot, ComponentType.SPEEDSTAT, 50 / 70)
    EntityManager:addComponent(EntityManager.dot, ComponentType.TEXTURE, Texture.new({ r = 1, g = 0.5, b = 0 }))
    EntityManager:addComponent(EntityManager.dot, ComponentType.SHAPE, Shape.new(ShapeType.CIRCLE, 0.75))
    EntityManager:addComponent(EntityManager.dot, ComponentType.TASKQUEUE, TaskQueue.new(EntityManager.dot))
    EntityManager:addComponent(EntityManager.dot, ComponentType.SCHEDULE, Schedule.new())
end

local function initBottomBar()
    local w, h = love.window.getMode()
    local win = Gui.newWindow(0, h * 0.9, w, h * 0.1)
    local minimized = false
    ---@param btn Button
    local function minimizeWindow(btn)
        w, h = love.window.getMode()
        if minimized then
            win.height = h * 0.1
            win.width = w
            win.y = h * 0.9
            btn.y = 10
            btn:updateText("-", true)
        else
            win.height = 0
            win.width = 0
            win.y = h
            btn.y = -40
            btn:updateText("+", true)
        end
        minimized = not minimized
    end
    local minButton = Gui.Button.new(win, 10, 10, nil, nil, 4, 4, "-", minimizeWindow)
end

function love.load(args)
    initSystems()
    initDot()
    initBottomBar()
    Slab.Initialize(args)
    overlayStats.load()
end

function love.update(dt)
    Camera:update(dt)
    PositionSystem:update(dt)
    MapManager:update()
    InputSystem:update()
    TaskManager:update(dt)
    Gui.update(dt)

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

function love.mousepressed(x, y, button, istouch) InputSystem:handleMousePressed(x, y, button, istouch) end

function love.wheelmoved(x, y)
    if love.keyboard.isDown("lctrl") then
        Logger:wheelmoved(x, y)
    else
        InputSystem:handleWheelMoved(x, y)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure) overlayStats.handleTouch(id, x, y, dx, dy, pressure) end

function love.resize()
    local newWidth, newHeight = love.window.getMode()
    -- Recalculate pixel size
    constants.pixelSize = newWidth / 40
    Gui.resize()
end

function love.draw()
    Camera:apply()
    RenderSystem:update(Camera:getVisibleBounds())
    Camera:unapply()
    LoadingIndicator:draw()
    Gui.draw()
    Slab.Draw()
    Logger:draw()
    overlayStats.draw()
end
