local enums = require("game.utils.enums")
local ComponentType = enums.ComponentType
local ZIndexing = require("game.utils.enums").ZIndexing
local FlexLove = require("game.libs.FlexLove")
local Gui = FlexLove.GUI
local Color = FlexLove.Color

---@class BottomBar
---@field window Window
---@field minimized boolean
---@field minimizeButton Button
local BottomBar = {}
BottomBar.__index = BottomBar
local instance

function BottomBar:init()
  if instance ~= nil then
    return instance
  end
  local self = setmetatable({}, BottomBar)

  local w, h = love.window.getMode()

  self.window = Gui.Window.new({
    x = 0,
    y = h * 0.9,
    z = ZIndexing.BottomBar,
    w = w,
    h = h * 0.1,
    border = { top = true },
    background = Color.new(0.2, 0.2, 0.2, 0.95),
  })

  self.minimizeButton = Gui.Button.new({
    parent = self.window,
    x = 10,
    y = 10,
    px = 4,
    py = 4,
    text = "-",
    textColor = Color.new(1, 1, 1),
    borderColor = Color.new(1, 1, 1),
    callback = function()
      self:toggleWindow()
    end,
  })
  local tabHeight = 20
  -- menu tab container
  Gui.Window.new({
    parent = self.window,
    y = h - tabHeight,
  })
  --Gui.Button.new({})
end

function BottomBar:showColonists()
  local colonists = EntityManager:query(ComponentType.COLONIST_TAG)
  for _, colonist in pairs(colonists) do
    EntityManager:getComponent(colonist, ComponentType.TEXTURE)
    Gui.Button.new({ parent = self.window })
  end
end

function BottomBar:highlightSelected()
  --- Check for selected colonist, if selected, then show details according to that colonist (schedule, health etc.), add (x) to clear selection and contextual menus
end

function BottomBar:showAdditionSelectedDetails() end

function BottomBar:toggleWindow()
  local w, h = love.window.getMode()
  if self.minimized then
    self.window.height = h * 0.1
    self.window.width = w
    self.window.y = h * 0.9
    self.minimizeButton.y = 10
    self.minimizeButton:updateText("-", true)
  else
    self.window.height = 0
    self.window.width = 0
    self.window.y = h
    self.minimizeButton.y = -40
    self.minimizeButton:updateText("+", true)
  end
  self.minimized = not self.minimized
end

return BottomBar:init()
