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

  -- Create the main window with flex layout
  self.window = Gui.new({
    x = 0,
    y = h * 0.9,
    z = ZIndexing.BottomBar,
    w = w,
    h = h * 0.1,
    border = { top = true },
    background = Color.new(0.2, 0.2, 0.2, 0.95),
  })

  -- Create minimize button (absolute positioning)
  self.minimizeButton = Gui.new({
    parent = self.window,
    x = 10,
    y = 10,
    w = 20,
    h = 20,
    padding = { top = 4, right = 4, bottom = 4, left = 4 },
    text = "-",
    textAlign = "center",
    positioning = "absolute",
    border = { top = true, right = true, bottom = true, left = true },
    textColor = Color.new(1, 1, 1),
    borderColor = Color.new(1, 1, 1),
    callback = function()
      self:toggleWindow()
    end,
  })

  -- Create a flex container for the menu tabs
  local tabHeight = 20
  local menuTab = Gui.new({
    parent = self.window,
    y = h * 0.1 - tabHeight,
    h = tabHeight,
    w = w,
    border = { top = true, right = true, bottom = true, left = true },
    borderColor = Color.new(1, 1, 1, 1),
    positioning = "flex",
    flexDirection = "horizontal",
    alignSelf = "center",
    justifyContent = "center",
    callback = function(ele)
      Logger:debug(ele.y .. " of " .. h)
    end,
  })

  Gui.new({
    parent = menuTab,
    text = "Colonists",
    textColor = Color.new(1, 1, 1, 1),
    border = { top = true, right = true, bottom = true, left = true },
  })

  Gui.new({
    parent = menuTab,
    text = "Schedule",
    textColor = Color.new(1, 1, 1, 1),
    border = { top = true, right = true, bottom = true, left = true },
  })

  return self
end

function BottomBar:showColonists()
  local colonists = EntityManager:query(ComponentType.COLONIST_TAG)
  -- Create a container for colonists with flex layout
  local colonistContainer = Gui.new({
    parent = self.window,
    positioning = "flex",
    flexDirection = "horizontal",
    justifyContent = "center",
    alignItems = "center",
    gap = 10,
    w = self.window.width,
    h = self.window.height * 0.8, -- Leave room for other UI elements
  })

  for _, colonist in pairs(colonists) do
    local name = EntityManager:getComponent(colonist, ComponentType.NAME)
    Gui.new({
      parent = colonistContainer,
      text = name,
      padding = { top = 4, right = 8, bottom = 4, left = 8 },
      border = { top = true, right = true, bottom = true, left = true },
      textColor = Color.new(1, 1, 1, 1),
    })
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
    self.minimizeButton.y = self.window.y + 10
    self.minimizeButton.text = "-"
  else
    self.window.height = 0
    self.window.width = 0
    self.window.y = h
    self.minimizeButton.y = self.window.y - 40
    self.minimizeButton.text = "+"
  end
  self.minimized = not self.minimized
end

return BottomBar.init()
