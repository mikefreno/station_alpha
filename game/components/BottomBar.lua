local enums = require("game.utils.enums")
local ComponentType = enums.ComponentType
local ZIndexing = require("game.utils.enums").ZIndexing
local FlexLove = require("game.libs.FlexLove")
local Gui = FlexLove.GUI
local Color = FlexLove.Color

---@enum Tabs
local Tabs = {
  COLONIST = 1,
  SCHEDULE = 2,
}

---@class BottomBar
---@field window Element
---@field minimized boolean
---@field minimizeButton Element
---@field tab Tabs
local BottomBar = {}
BottomBar.__index = BottomBar
local instance

function BottomBar.init()
  if instance ~= nil then
    return instance
  end
  local self = setmetatable({}, BottomBar)
  self.tab = Tabs.COLONIST

  -- Create the main window with flex layout
  self.window = Gui.new({
    x = 0,
    y = "90%",
    z = ZIndexing.BottomBar,
    width = "100%",
    height = "10%",
    border = { top = true },
    background = Color.new(0.2, 0.2, 0.2, 1.0),
  })

  self.minimizeButton = Gui.new({
    x = "2%",
    y = "92%",
    padding = { vertical = 4, horizontal = 8 },
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
  local menuTab = Gui.new({
    parent = self.window,
    width = "100%",
    height = "100%",
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
    padding = { horizontal = 8, vertical = 4 },
    border = { top = true, right = true, bottom = true, left = true },
    borderColor = Color.new(1, 1, 1, 1),
    callback = function(ele)
      Logger:debug("Colonists button: " .. ele.y)
      self.tab = Tabs.COLONIST
      self:renderCurrentTab()
    end,
  })

  Gui.new({
    parent = menuTab,
    text = "Schedule",
    textColor = Color.new(1, 1, 1, 1),
    textAlign = "center",
    padding = { horizontal = 8, vertical = 4 },
    border = { top = true, right = true, bottom = true, left = true },
    borderColor = Color.new(1, 1, 1, 1),
    callback = function(ele)
      Logger:debug("Schedule button: " .. ele.y)
      self.tab = Tabs.SCHEDULE
      self:renderCurrentTab()
    end,
  })

  self:renderCurrentTab()

  return self
end

function BottomBar:renderCurrentTab()
  -- Map tabs to their rendering functions
  local tabMap = {
    [Tabs.COLONIST] = self.renderColonistsTab,
    [Tabs.SCHEDULE] = self.renderScheduleTab,
  }

  local renderFunction = tabMap[self.tab]
  if renderFunction then
    renderFunction(self)
  else
    Logger:error("Invalid tab selected: " .. tostring(self.tab))
  end
end

function BottomBar:renderColonistsTab()
  Logger:debug("showing colonists tab")
  local colonists = EntityManager:query(ComponentType.COLONIST_TAG)
  self.colonistContainer = Gui.new({
    parent = self.window,
    background = Color.new(0.3, 0.8, 0.3),
    positioning = "flex",
    flexDirection = "horizontal",
    justifyContent = "center",
    alignItems = "center",
    gap = 10,
    width = "100%",
    height = "80%",
  })

  for _, colonist in pairs(colonists) do
    local name = EntityManager:getComponent(colonist, ComponentType.NAME)
    Gui.new({
      parent = self.colonistContainer,
      text = name,
      background = Color.new(0.6, 0.2, 0.4),
      padding = { horizontal = 8, vertical = 4 },
      border = { top = true, right = true, bottom = true, left = true },
      textColor = Color.new(1, 1, 1, 1),
    })
  end
end

function BottomBar:renderScheduleTab()
  Logger:debug("showing schedule tab")
  self.colonistContainer:destroy()
end

function BottomBar:highlightSelected()
  --- Check for selected colonist, if selected, then show details according to that colonist (schedule, health etc.), add (x) to clear selection and contextual menus
end

function BottomBar:showAdditionSelectedDetails() end

function BottomBar:toggleWindow()
  if self.minimized then
    self.window:updateOpacity(1)
    self.minimizeButton:updateText("-", false)
  else
    self.window:updateOpacity(0)
    self.minimizeButton:updateText("+", false)
  end
  self.minimized = not self.minimized
end

return BottomBar.init()
