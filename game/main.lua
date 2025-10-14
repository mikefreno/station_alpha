Logger = require("logger"):init()
EntityManager = require("systems.EntityManager")
BottomBar = require("components.BottomBar").init()
local Schedule = require("components.Schedule")
local enums = require("utils.enums")
local mapManager = require("systems.MapManager")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local InputSystem = require("systems.Input")
local LoadingIndicator = require("components.LoadingIndicator")
local PositionSystem = require("systems.Position")
local RenderSystem = require("systems.Render")
local Shape = require("components.Shape")
local TaskQueue = require("components.task.Queue")
local Texture = require("components.Texture")
local Vec2 = require("utils.Vec2")
local camera = require("components.Camera")
local constants = require("utils.constants")
local overlayStats = require("libs.OverlayStats")
local pathfinder = require("systems.PathFinder")
local taskManager = require("systems.TaskManager")
local EventBus = require("systems.EventBus")
local FlexLove = require("libs.FlexLove")
local Gui = FlexLove.GUI

---GUI Init---
require("components.PauseMenu")
require("components.RightClickMenu")
--------------

local function isLoading()
  if not MapManager.graph or MapManager.dirtyGraph == true then
    return true
  end
end

local function initSystems()
  Camera = camera.new()
  MapManager = mapManager.new(constants.MAP_W, constants.MAP_H)
  MapManager:createLevelMap()
  TaskManager = taskManager.new()
  Pathfinder = pathfinder.new()
  EventBus = EventBus
end

---NOTE: temporary for demoing purposes---
local function initDot()
  local dot = EntityManager:createEntity()
  EntityManager:addComponent(dot, ComponentType.NAME, "Testing Dot")
  EntityManager:addComponent(dot, ComponentType.POSITION, Vec2.new(1, 1))
  EntityManager:addComponent(dot, ComponentType.VELOCITY, Vec2.new())
  EntityManager:addComponent(dot, ComponentType.SPEEDSTAT, 0.25)
  EntityManager:addComponent(dot, ComponentType.TEXTURE, Texture.new({ r = 1, g = 0.5, b = 0 }))
  EntityManager:addComponent(dot, ComponentType.SHAPE, Shape.new(ShapeType.CIRCLE, 0.75))
  EntityManager:addComponent(dot, ComponentType.TASKQUEUE, TaskQueue.new(dot))
  EntityManager:addComponent(dot, ComponentType.SCHEDULE, Schedule.new())
  EntityManager:addComponent(dot, ComponentType.COLONIST_TAG, true)
  local square = EntityManager:createEntity()
  EntityManager:addComponent(square, ComponentType.NAME, "Testing Square")
  EntityManager:addComponent(square, ComponentType.POSITION, Vec2.new(2, 1))
  EntityManager:addComponent(square, ComponentType.VELOCITY, Vec2.new())
  EntityManager:addComponent(square, ComponentType.SPEEDSTAT, 0.5)
  EntityManager:addComponent(square, ComponentType.TEXTURE, Texture.new({ r = 1, g = 0.5, b = 0 }))
  EntityManager:addComponent(square, ComponentType.SHAPE, Shape.new(ShapeType.SQUARE, 1))
  EntityManager:addComponent(square, ComponentType.TASKQUEUE, TaskQueue.new(square))
  EntityManager:addComponent(square, ComponentType.SCHEDULE, Schedule.new())
  EntityManager:addComponent(square, ComponentType.COLONIST_TAG, true)
end

function love.load()
  Gui.init({ theme = "space" })

  initSystems()
  initDot()

  overlayStats.load()
end

function love.update(dt)
  Camera:update(dt)
  PositionSystem:update(dt)
  MapManager:update()
  InputSystem:update()
  TaskManager:update(dt)
  Gui.update(dt)

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
  InputSystem:keypressed(key, scancode, isrepeat)
end

function love.mousepressed(x, y, button, istouch)
  InputSystem:handleMousePressed(x, y, button, istouch)
end

function love.wheelmoved(x, y)
  if love.keyboard.isDown("lctrl") then
    Logger:wheelmoved(x, y)
  else
    InputSystem:handleWheelMoved(x, y)
  end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  overlayStats.handleTouch(id, x, y, dx, dy, pressure)
end

function love.resize()
  local newWidth = love.window.getMode()
  constants.pixelSize = newWidth / 40
  Gui.resize()
end

function love.draw()
  Camera:apply()
  RenderSystem:update(Camera:getVisibleBounds())
  Camera:unapply()
  LoadingIndicator:draw()
  Gui.draw()
  Logger:draw()
  overlayStats.draw()
end
