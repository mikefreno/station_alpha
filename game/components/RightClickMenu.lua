local EntityManager = require("game.systems.EntityManager")
local Vec2 = require("game.utils.Vec2")
local constants = require("game.utils.constants")
local ComponentType = require("game.utils.enums").ComponentType
local Gui = require("game.libs.MyGUI")
local enums = require("game.utils.enums")
local Color = require("game.utils.color")
local Positioning, FlexDirection, JustifyContent, AlignContent, AlignItems =
  enums.Positioning, enums.FlexDirection, enums.JustifyContent, enums.AlignContent, enums.AlignItems

---@class RightClickMenu
---@field worldPosition Vec2?
---@field gridPosition Vec2?
---@field showing boolean
---@field contents {}
---@field hovered boolean
---@field window Window?
local RightClickMenu = {}
RightClickMenu.__index = RightClickMenu

local instance

function RightClickMenu.init()
  if instance ~= nil then
    return instance
  end
  Logger:debug("creating new RCM")
  local self = setmetatable({}, RightClickMenu)
  self.worldPosition = nil
  self.gridPosition = nil
  self.showing = false
  self.contents = {}
  self.hovered = false
  self.window = nil
  instance = self
  return self
end

function RightClickMenu:updatePosition(x, y)
  local vec = Vec2.new(x, y)
  self.worldPosition = vec
  Logger:debug(vec)
  self.gridPosition = MapManager:worldToGrid(vec)
  Logger:debug(self.gridPosition)

  self.showing = true
end

function RightClickMenu:draw()
  if self.showing then
    self.window = Gui.Window.new({
      x = self.worldPosition.x,
      y = self.worldPosition.y,
      w = 120,
      h = 200,
      border = { top = true, right = true, bottom = true, left = true },
      background = Color.new(0.6, 0.6, 0.8, 1),
      initVisible = true,
      textColor = Color.new(1, 1, 1, 1),
      positioning = Positioning.FLEX,
      flexDirection = FlexDirection.VERTICAL,
      gap = 10,
    })

    local selected = EntityManager:find(ComponentType.SELECTED, true)

    RightClickMenu:setupSelectionBasedComponents(selected)
  elseif self.window ~= nil then
    self.window:destroy()
    self.window = nil
  end
end

function RightClickMenu:handleMousePressed(x, y, button, istouch)
  if self.window then
    local bounds = self.window:getBounds()
    if x < bounds.x or x > bounds.x + bounds.width or y < bounds.y or y > bounds.y + bounds.height then
      self:hide()
    end
  end
end

function RightClickMenu:hide()
  Logger:debug("hide called")
  self.showing = false
  self.position = nil
  self.gridPosition = nil
  if self.window then
    self.window:destroy()
    self.window = nil
  end
end

---@param entity integer?
function RightClickMenu:setupSelectionBasedComponents(entity)
  if self.gridPosition == nil then
    Logger:debug("no grid")
    Logger:debug(self.position)
    return
  end
  if entity then
    local targetEntity =
      EntityManager:findNearest(ComponentType.POSITION, self.gridPosition, { ComponentType.MAPTILETAG })
    -- can the entity move?
    local speedStat = EntityManager:getComponent(entity, ComponentType.SPEEDSTAT)
    if speedStat then
      self:addMoveTo(entity)
    end
  end
end

---@param entity integer
function RightClickMenu:addMoveTo(entity)
  local entityPos = EntityManager:getComponent(entity, ComponentType.POSITION)
  local function GoTo()
    local entityShape = EntityManager:getComponent(entity, ComponentType.SHAPE)
    local path = Pathfinder:findPath(entityPos:add(entityShape.size / 2, entityShape.size / 2), self.gridPosition)
    if path ~= nil then
      TaskManager:newPath(entity, path)
    end
    self.showing = false
    ButtonPressed = false
  end

  Gui.Button.new({
    parent = self.window,
    background = Color.new(0.2, 0.7, 0.7, 0.9),
    text = "Go To: " .. self.gridPosition.x .. "," .. self.gridPosition.y,
    callback = GoTo,
    positioning = Positioning.FLEX,
  })
end

function RightClickMenu:nonTileTargetInteractions() end

return RightClickMenu.init()
