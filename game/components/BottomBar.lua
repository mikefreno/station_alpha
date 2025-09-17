local enums = require("game.utils.enums")
local ComponentType = enums.ComponentType
local ZIndexing = require("game.utils.enums").ZIndexing
local FlexLove = require("game.libs.FlexLove")
local Gui = FlexLove.GUI
local Color = FlexLove.Color

---@class BottomBar
---@field window Element
---@field minimized boolean
---@field minimizeButton Element
---@field mode string
local BottomBar = {}
BottomBar.__index = BottomBar
local instance

function BottomBar.init()
  if instance ~= nil then
    return instance
  end
  local self = setmetatable({}, BottomBar)
  self.mode = "colonists"

  local w, h = love.window.getMode()

  self.window = Gui.Element.new({
    x = 0,
    y = h * 0.9,
    z = ZIndexing.BottomBar,
    w = w,
    h = h * 0.1,
    border = { top = true },
    positioning = "flex",
    alignContent = "center",
    justifyContent = "flex-end",
    background = Color.new(0.2, 0.2, 0.2, 0.95),
  })

  self.minimizeButton = Gui.new({
    parent = self.window,
    x = 10,
    y = 10,
    padding = { top = 4, right = 4, bottom = 4, left = 4 },
    text = "-",
    positioning = "absolute",
    border = { top = true, right = true, bottom = true, left = true },
    textColor = Color.new(1, 1, 1),
    borderColor = Color.new(1, 1, 1),
    callback = function()
      self:toggleWindow()
    end,
  })
  local tabHeight = 20
  -- menu tab container
  local menuTab = Gui.new({
    parent = self.window,
    positioning = "absolute",
    y = h * 0.1 - tabHeight,
  })
  Gui.new({
    parent = menuTab,
    text = "Colonists",
    textColor = Color.new(1, 1, 1, 1),
    border = { top = true, right = true, bottom = true, left = true },
    w = 80,
  })
  Gui.new({
    parent = menuTab,
    text = "Schedule",
    textColor = Color.new(1, 1, 1, 1),
    border = { top = true, right = true, bottom = true, left = true },
    w = 80,
  })
end

function BottomBar:showColonists()
  local colonists = EntityManager:query(ComponentType.COLONIST_TAG)
  for _, colonist in pairs(colonists) do
    local texture = EntityManager:getComponent(colonist, ComponentType.TEXTURE)
    local name = EntityManager:getComponent(colonist, ComponentType.NAME)
    Gui.new({ parent = self.window, text = name })
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

return BottomBar.init()
