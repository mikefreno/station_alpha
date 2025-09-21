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

  -- Create the main window with flex layout
  self.window = Gui.new({
    x = 0,
    y = "90%",
    z = ZIndexing.BottomBar,
    w = "100%",
    h = "10%",
    border = { top = true },
    background = Color.new(0.2, 0.2, 0.2, 1.0),
  })

  -- Create minimize button (absolute positioning)
  self.minimizeButton = Gui.new({
    parent = self.window,
    x = "2%",
    y = "2%",
    w = 20,
    h = 20,
    padding = { top = 4, right = 4, bottom = 4, left = 4 },
    text = "-",
    textAlign = "center",
    positioning = "relative",
    border = { top = true, right = true, bottom = true, left = true },
    textColor = Color.new(1, 1, 1),
    borderColor = Color.new(1, 1, 1),
    callback = function()
      self:toggleWindow()
    end,
  })

  -- Create a flex container for the menu tabs
  local menuTab = Gui.new({
    parent = self.window,
    w = "100%",
    h = "100%",
    alignItems = "flex-end",
    positioning = "flex",
    flexDirection = "horizontal",
    justifyContent = "center",
  })

  Gui.new({
    parent = menuTab,
    text = "Colonists",
    textColor = Color.new(1, 1, 1, 1),
    textAlign = "center",
    border = { top = true, right = true, bottom = true, left = true },
    borderColor = Color.new(1, 1, 1, 1),
    callback = function(ele)
      Logger:debug("Colonists button: " .. ele.y)
    end,
  })

  Gui.new({
    parent = menuTab,
    text = "Schedule",
    textColor = Color.new(1, 1, 1, 1),
    textAlign = "center",
    border = { top = true, right = true, bottom = true, left = true },
    borderColor = Color.new(1, 1, 1, 1),
    callback = function(ele)
      Logger:debug("Schedule button: " .. ele.y)
    end,
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
  if self.minimized then
    self.window:updateOpacity(1)
    self.minimizeButton.text = "-"
  else
    self.window:updateOpacity(0)
    self.minimizeButton.text = "+"
  end
  self.minimized = not self.minimized
end

return BottomBar.init()
