local EntityManager = require("systems.EntityManager")
local Vec2 = require("utils.Vec2")
local constants = require("utils.constants")
local ComponentType = require("utils.enums").ComponentType
local ZIndexing = require("utils.enums").ZIndexing
local FlexLove = require("libs.FlexLove")
local MovementTask = require("components.task.movement")
local Gui = FlexLove.GUI
local Color = FlexLove.Color
local enums = FlexLove.enums
local Positioning, FlexDirection, JustifyContent, AlignContent, AlignItems =
  enums.Positioning, enums.FlexDirection, enums.JustifyContent, enums.AlignContent, enums.AlignItems
local MapManager = require("systems.MapManager")
local EventBus = require("systems.EventBus")
local Camera = require("components.Camera")

---@class RightClickMenu
---@field worldPosition Vec2?
---@field gridPosition Vec2?
---@field contents {}
---@field hovered boolean
---@field window Element?
local RightClickMenu = {}
RightClickMenu.__index = RightClickMenu

local instance

function RightClickMenu.init()
  if instance ~= nil then
    return instance
  end
  local self = setmetatable({}, RightClickMenu)
  self.worldPosition = nil
  self.gridPosition = nil
  self.contents = {}
  self.hovered = false
  self.window = nil

  EventBus:on("camera_moved", function(data)
    if data and data.diff and self.gridPosition then
      self.worldPosition:mutSub(data.diff:mul(constants.pixelSize))
      self:set()
    end
  end)

  instance = self
  return self
end

function RightClickMenu:updatePosition(x, y)
  self:destroy()
  local vec = Vec2.new(x, y)
  self.worldPosition = vec
  self.gridPosition = MapManager:worldToGrid(vec)
  self:set()
end

function RightClickMenu:set()
  if self.window then
    self.window:destroy()
  end
  self.window = Gui.new({
    x = self.worldPosition.x,
    y = self.worldPosition.y,
    z = ZIndexing.RightClickMenu,
    border = { top = true, right = true, bottom = true, left = true },
    background = Color.new(0.6, 0.6, 0.8, 1),
    textColor = Color.new(1, 1, 1, 1),
    positioning = Positioning.FLEX,
    flexDirection = FlexDirection.VERTICAL,
    gap = 10,
  })

  local selected = EntityManager:find(ComponentType.SELECTED, true)

  if selected then
    self:setupSelectionBasedComponents(selected)
  end
end

function RightClickMenu:destroy()
  if self.window then
    self.window:destroy()
    self.window = nil
  end
end

function RightClickMenu:clickWithin(x, y)
  if self.window == nil then
    return false
  end
  local bounds = self.window:getBounds()
  if x < bounds.x or x > bounds.x + bounds.width or y < bounds.y or y > bounds.y + bounds.height then
    return false
  end
  return true
end

function RightClickMenu:handleMousePressed(x, y, button, istouch)
  if not self:clickWithin(x, y) then
    self:destroy()
  end
end

---@param entity integer
function RightClickMenu:setupSelectionBasedComponents(entity)
  local speedStat = EntityManager:getComponent(entity, ComponentType.SPEEDSTAT)
  if speedStat then
    self:addMoveTo(entity)
  end
end

---@param entity integer
function RightClickMenu:addMoveTo(entity)
  local function GoTo()
    local entityTQ = EntityManager:getComponent(entity, ComponentType.TASKQUEUE)
    entityTQ:reset()
    entityTQ:push(MovementTask.new(entity, self.gridPosition))
    ButtonPressed = false
  end
  local entityName = EntityManager:getComponent(entity, ComponentType.NAME)

  Gui.new({
    parent = self.window,
    background = Color.new(0.2, 0.7, 0.7, 0.9),
    text = "Move " .. entityName .. " To: " .. self.gridPosition.x .. "," .. self.gridPosition.y,
    callback = GoTo,
  })
end

function RightClickMenu:nonTileTargetInteractions() end

return RightClickMenu.init()
