Logger = require("game.logger"):init()
local Schedule = require("game.components.Schedule")
local enums = require("game.utils.enums")
local mapManager = require("game.systems.MapManager")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
EntityManager = require("game.systems.EntityManager")
local InputSystem = require("game.systems.Input")
local LoadingIndicator = require("game.components.LoadingIndicator")
local PositionSystem = require("game.systems.Position")
local RenderSystem = require("game.systems.Render")
local Shape = require("game.components.Shape")
local TaskQueue = require("game.components.TaskQueue")
local Texture = require("game.components.Texture")
local Vec2 = require("game.utils.Vec2")
local camera = require("game.components.Camera")
local constants = require("game.utils.constants")
local overlayStats = require("game.libs.OverlayStats")
local pathfinder = require("game.systems.PathFinder")
local taskManager = require("game.systems.TaskManager")
local TaskExecutionSystem = require("game.systems.TaskExecutionSystem")
local MovementSystem = require("game.systems.MovementSystem")
local FlexLove = require("game.libs.FlexLove")
local Gui = FlexLove.GUI

---GUI Init---
require("game.components.PauseMenu")
require("game.components.RightClickMenu")
require("game.components.BottomBar")
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
  
  -- Initialize ECS task systems
  TaskExecutionSystem:init()
  MovementSystem = MovementSystem.new()
  
  -- Register processors with TaskExecutionSystem
  MovementSystem:registerWithTaskExecutionSystem(TaskExecutionSystem)
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
  
  -- Create TaskQueue and Schedule (always in ECS mode)
  local taskQueue = TaskQueue.new(dot)
  EntityManager:addComponent(dot, ComponentType.TASKQUEUE, taskQueue)
  
  local schedule = Schedule.new()
  EntityManager:addComponent(dot, ComponentType.SCHEDULE, schedule)
  
  EntityManager:addComponent(dot, ComponentType.COLONIST_TAG, true)
end

function love.load()
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
  
  -- ECS Task Systems
  TaskExecutionSystem:update(dt)
  MovementSystem:update(dt)
  
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
