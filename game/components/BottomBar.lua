local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local ZIndexing = require("utils.enums").ZIndexing
local FlexLove = require("libs.FlexLove")
local Gui = FlexLove.GUI
local Color = FlexLove.Color
local Theme = FlexLove.Theme
local EventBus = require("systems.EventBus")
local switch = require("utils.helperFunctions").switch
local scheduleColors = require("utils.colors").schedule

---@enum Tabs
local Tabs = {
  COLONIST = 1,
  SCHEDULE = 2,
}

---@class BottomBar
---@field mainContainer Element
---@field contentContainer Element
---@field tabContainer Element
---@field minimized boolean
---@field minimizeButton Element
---@field tab Tabs
---@field tabButtons table
local BottomBar = {}
BottomBar.__index = BottomBar
local instance

function BottomBar.init()
  if instance ~= nil then
    return instance
  end
  local self = setmetatable({}, BottomBar)
  self.tab = Tabs.COLONIST
  self.colonistContainer = nil
  self.tabButtons = {}

  -- Create the main window with flex layout
  self.mainContainer = Gui.new({
    x = 0,
    y = "85%",
    z = ZIndexing.BottomBar,
    positioning = "flex",
    flexDirection = "vertical",
    justifyContent = "center",
    themeComponent = "framev2",
    scaleCorners = 1.5,
    width = "100%",
    height = "15%",
  })

  self.minimized = false

  -- Create minimize button (always present, positioned absolutely)
  self.minimizeButton = Gui.new({
    x = "0.5vw",
    y = "85.5vh",
    z = ZIndexing.BottomBar + 5,
    width = "2vw",
    height = "2vw",
    text = "-",
    textAlign = "center",
    positioning = "absolute",
    themeComponent = "buttonv1",
    callback = function()
      self:toggleWindow()
    end,
  })

  self.contentContainer = Gui.new({
    parent = self.mainContainer,
    width = "100%",
    height = "70%",
    positioning = "flex",
  })

  -- Create a flex container for the menu tabs
  self.tabContainer = Gui.new({
    parent = self.mainContainer,
    width = "100%",
    height = "20%",
    positioning = "flex",
    flexDirection = "horizontal",
    justifyContent = "center",
    gap = "5%",
  })

  Gui.new({
    parent = self.tabContainer,
    text = "Colonists",
    textAlign = "center",
    themeComponent = "buttonv1",
    disabled = self.tab == Tabs.COLONIST,
    callback = function(_, event)
      if event.type == "release" then
        self.tab = Tabs.COLONIST
        self:renderCurrentTab()
      end
    end,
  })

  Gui.new({
    parent = self.tabContainer,
    text = "Schedule",
    textAlign = "center",
    themeComponent = "buttonv1",
    disabled = self.tab == Tabs.SCHEDULE,
    callback = function(_, event)
      if event.type == "release" then
        self.tab = Tabs.SCHEDULE
        self:renderCurrentTab()
      end
    end,
  })
  EventBus:on("colonist_added", function()
    self:renderCurrentTab()
  end)

  return self
end

function BottomBar:renderCurrentTab()
  local tabMap = {
    [Tabs.COLONIST] = self.renderColonistsTab,
    [Tabs.SCHEDULE] = self.renderScheduleTab,
  }

  local renderFunction = tabMap[self.tab]
  if renderFunction then
    self:tabCleanup()
    renderFunction(self)
  else
    Logger:error("Invalid tab selected: " .. tostring(self.tab))
  end
  self:updateTabButtonStates()
end

function BottomBar:tabCleanup()
  if self.colonistContainer then
    self.colonistContainer:destroy()
    self.colonistContainer = nil
  end
  if self.scheduleContainer then
    self.scheduleContainer:destroy()
    self.scheduleContainer = nil
  end
end

function BottomBar:renderColonistsTab()
  local colonists = EntityManager:query(ComponentType.COLONIST_TAG)
  self.colonistContainer = Gui.new({
    parent = self.contentContainer,
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
      textAlign = "center",
      themeComponent = "buttonv1",
      callback = function()
        EntityManager:addComponent(colonist, ComponentType.SELECTED, true)
        local colPos = EntityManager:getComponent(colonist, ComponentType.POSITION)
        -- Emit event instead of directly calling Camera
        EventBus:emit("entity_selected", { entity = colonist, position = colPos })
      end,
    })
  end
end

function BottomBar:renderScheduleTab()
  local colonists = EntityManager:query(ComponentType.COLONIST_TAG)
  local TaskType = enums.TaskType

  -- Get assignable task types (exclude MOVETO)
  local taskTypes = {}
  local taskNames = {}
  for name, value in pairs(TaskType) do
    if value ~= TaskType.MOVETO then
      table.insert(taskTypes, { name = name, value = value })
    end
  end
  -- Sort by value to maintain consistent order
  table.sort(taskTypes, function(a, b)
    return a.value < b.value
  end)
  for _, task in ipairs(taskTypes) do
    table.insert(taskNames, task.name)
  end

  -- Calculate grid dimensions: +1 for header row and column
  local numRows = #colonists + 1 -- +1 for header row
  local numColumns = #taskTypes + 1 -- +1 for colonist names column

  self.scheduleContainer = Gui.new({
    parent = self.contentContainer,
    width = "100%",
    height = "80%",
    backgroundColor = Color.new(1),
    positioning = "grid",
    gridRows = numRows,
    gridColumns = numColumns,
    columnGap = 2,
    rowGap = 2,
    theme = "space",
    alignItems = "stretch",
  })

  local accentColor = Theme.getColor("primary")
  local textColor = Theme.getColor("text")

  -- Create header row (first row)
  -- Top-left corner cell (empty)
  Gui.new({
    parent = self.scheduleContainer,
  })

  -- Task type headers
  for _, taskName in ipairs(taskNames) do
    Gui.new({
      parent = self.scheduleContainer,
      text = taskName,
      textColor = textColor,
      textAlign = "center",
      backgroundColor = Color.new(0, 0, 0, 0.3),
      border = { top = true, right = true, bottom = true, left = true },
      borderColor = accentColor,
      textSize = 10,
    })
  end

  -- Create rows for each colonist
  for _, colonist in ipairs(colonists) do
    local name = EntityManager:getComponent(colonist, ComponentType.NAME)

    -- Colonist name cell (first column)
    Gui.new({
      parent = self.scheduleContainer,
      text = name or "Unknown",
      backgroundColor = Color.new(0, 0, 0, 0.3),
      textColor = Color.new(1, 1, 1, 1),
      textAlign = "center",
      border = { top = true, right = true, bottom = true, left = true },
      borderColor = accentColor,
      textSize = 10,
    })

    -- Task cells for this colonist
    for _, task in ipairs(taskTypes) do
      local schedule = EntityManager:getComponent(colonist, ComponentType.SCHEDULE)
      if not task or not schedule then
        return
      end

      Gui.new({
        parent = self.scheduleContainer,
        text = schedule:getStrVal(task.value),
        textColor = schedule:getColor(task.value),
        textAlign = "center",
        border = { top = true, right = true, bottom = true, left = true },
        borderColor = Color.new(0.5, 0.5, 0.5, 1.0),
        textSize = 12,
        callback = function(elem, event)
          switch(event.type, {
            ["click"] = function()
              if event.modifiers.shift then
                schedule:setToMax(task.value)
                return
              end
              schedule:increment(task.value)
            end,
            ["rightclick"] = function()
              if event.modifiers.shift then
                schedule:setToMin(task.value)
                return
              end
              schedule:decrement(task.value)
            end,
          })
          elem.textColor = schedule:getColor(task.value)
          elem:updateText(schedule:getStrVal(task.value))
        end,
      })
    end
  end
end

function BottomBar:highlightSelected()
  --- Check for selected colonist, if selected, then show details according to that colonist (schedule, health etc.), add (x) to clear selection and contextual menus
end

function BottomBar:showAdditionSelectedDetails() end

function BottomBar:toggleWindow()
  if self.minimized then
    self.mainContainer:updateOpacity(1)
    self.minimizeButton:updateText("-", false)
  else
    self.mainContainer:updateOpacity(0)
    self.minimizeButton:updateText("+", false)
    self.minimizeButton:updateOpacity(1)
  end
  self.minimized = not self.minimized
end

function BottomBar:updateTabButtonStates()
  for _, button in ipairs(self.tabButtons) do
    if button then
      -- Update the disabled state based on current tab selection
      local isDisabled = (button.tabValue == self.tab)
      button:updateDisabled(isDisabled)
    end
  end
end

return BottomBar
