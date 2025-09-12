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
---@field position Vec2?
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
  self.position = nil
  self.showing = false
  self.contents = {}
  self.hovered = false
  self.window = nil
  instance = self
  return self
end

function RightClickMenu:updatePosition(x, y)
  self.position = Vec2.new(x, y)
  self.showing = true
end

function RightClickMenu:draw()
  if self.showing then
    self.window = Gui.Window.new({
      x = self.position.x,
      y = self.position.y,
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

    self.window:draw()
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
  self.showing = false
  self.position = nil
  if self.window then
    self.window:destroy()
    self.window = nil
  end
end

---@param entity integer?
function RightClickMenu:setupSelectionBasedComponents(entity)
  if entity then
    Logger:debug(self.position)
    if not self.position then
      return
    end
    local gridPos = MapManager:worldToGrid(self.position)
    local targetEntity = EntityManager:findNearest(ComponentType.POSITION, gridPos, { ComponentType.MAPTILETAG })
    -- can the entity move?
    local speedStat = EntityManager:getComponent(entity, ComponentType.SPEEDSTAT)
    Logger:debug(speedStat)
    if speedStat then
      self:addMoveTo(entity, gridPos)
    end
  end
end

---@param entity integer
---@param gridPos Vec2
function RightClickMenu:addMoveTo(entity, gridPos)
  local entityPos = EntityManager:getComponent(entity, ComponentType.POSITION)
  local function GoTo()
    local entityShape = EntityManager:getComponent(entity, ComponentType.SHAPE)
    local path = Pathfinder:findPath(entityPos:add(entityShape.size / 2, entityShape.size / 2), gridPos)
    if path ~= nil then
      TaskManager:newPath(entity, path)
    end
    self.showing = false
    ButtonPressed = false
  end

  Gui.Button.new({
    parent = self.window,
    background = Color.new(0.2, 0.7, 0.7, 0.9),
    text = "Go To: " .. gridPos.x .. "," .. gridPos.y,
    callback = GoTo,
    positioning = Positioning.FLEX,
  })
end

function RightClickMenu:nonTileTargetInteractions() end

return RightClickMenu.init()
