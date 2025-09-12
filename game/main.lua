Logger = require("game.logger"):init()
local Color = require("game.utils.color")
local Schedule = require("game.components.Schedule")
local enums = require("game.utils.enums")
local mapManager = require("game.systems.MapManager")
local RightClickMenu = require("game.components.RightClickMenu")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TaskType = enums.TaskType
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
local PauseMenu = require("game.components.PauseMenu")
local Gui = require("game.libs.MyGUI")

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
end

---NOTE: temporary for demoing purposes---
local function initDot()
  local dot = EntityManager:createEntity()
  EntityManager:addComponent(dot, ComponentType.NAME, "Testing Dot")
  EntityManager:addComponent(dot, ComponentType.POSITION, Vec2.new(1, 1))
  EntityManager:addComponent(dot, ComponentType.VELOCITY, Vec2.new())
  -- 100 meters(50 tiles) in 70 seconds
  EntityManager:addComponent(dot, ComponentType.SPEEDSTAT, 50 / 70)
  EntityManager:addComponent(dot, ComponentType.TEXTURE, Texture.new({ r = 1, g = 0.5, b = 0 }))
  EntityManager:addComponent(dot, ComponentType.SHAPE, Shape.new(ShapeType.CIRCLE, 0.75))
  EntityManager:addComponent(dot, ComponentType.TASKQUEUE, TaskQueue.new(dot))
  EntityManager:addComponent(dot, ComponentType.SCHEDULE, Schedule.new())
end

local function initBottomBar()
  local w, h = love.window.getMode()
  BottomBar = Gui.Window.new({
    x = 0,
    y = h * 0.9,
    w = w,
    h = h * 0.1,
    border = { top = true },
    background = Color.new(0.2, 0.2, 0.2, 0.95),
  })
  local minimized = false
  ---@param btn Button
  local function minimizeWindow(btn)
    w, h = love.window.getMode()
    if minimized then
      BottomBar.height = h * 0.1
      BottomBar.width = w
      BottomBar.y = h * 0.9
      btn.y = 10
      btn:updateText("-", true)
    else
      BottomBar.height = 0
      BottomBar.width = 0
      BottomBar.y = h
      btn.y = -40
      btn:updateText("+", true)
    end
    minimized = not minimized
  end
  local minButton =
    Gui.Button.new({ parent = BottomBar, x = 10, y = 10, px = 4, py = 4, text = "-", callback = minimizeWindow })
end

function love.load()
  initSystems()
  initDot()
  initBottomBar()
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
  -- Forward keypress to input system if needed
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
  --RightClickMenu:draw()
  --BottomBar:draw()
  --PauseMenu:draw()
  Gui.draw()
  Logger:draw()
  overlayStats.draw()
end
