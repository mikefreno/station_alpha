local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local ZIndexing = require("utils.enums").ZIndexing
local FlexLove = require("libs.FlexLove")
local Gui = FlexLove.GUI
local Color = FlexLove.Color
local EventBus = require("systems.EventBus")

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
  self.colonistContainer = nil

  -- Create the main window with flex layout
  self.window = Gui.new({
    x = 0,
    y = "85%",
    z = ZIndexing.BottomBar,
    themeComponent = "panel",
    backgroundColor = Color.new(0.2, 0.2, 0.2, 1.0),
    width = "100%",
    height = "15%",
    cornerRadius = { topLeft = 20, topRight = 20 },
  })

  self.minimizeButton = Gui.new({
    parent = self.window,
    x = "0.5%",
    y = "5%",
    z = ZIndexing.BottomBar + 20,
    padding = { top = 3, bottom = 5, horizontal = 8 },
    text = "-",
    textAlign = "center",
    positioning = "flex",
    themeComponent = "button",
    --border = { top = true, right = true, bottom = true, left = true },
    textColor = Color.new(1, 1, 1),
    --borderColor = Color.new(1, 1, 1),
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
    padding = { horizontal = 16, vertical = 4 },
    themeComponent = "button",
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
    padding = { horizontal = 16, vertical = 4 },
    themeComponent = "button",
    callback = function(ele)
      Logger:debug("Schedule button: " .. ele.y)
      self.tab = Tabs.SCHEDULE
      self:renderCurrentTab()
    end,
  })

  --self:renderCurrentTab() -- would prefer this, but based on timing, must be called after dot - may change on actual colonist implementation

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
  Logger:debug("showing colonists tab")

  local colonists = EntityManager:query(ComponentType.COLONIST_TAG)
  self.colonistContainer = Gui.new({
    parent = self.window,
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
      padding = { horizontal = 32, vertical = 8 },
      textColor = Color.new(1, 1, 1, 1),
      themeComponent = "button",
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
  Logger:debug("showing schedule tab")

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
    parent = self.window,
    width = "100%",
    height = "80%",
    padding = { horizontal = 10, vertical = 8 },
    positioning = "grid",
    gridRows = numRows,
    gridColumns = numColumns,
    columnGap = 2,
    rowGap = 2,
    alignItems = "stretch",
  })

  -- Create header row (first row)
  -- Top-left corner cell (empty)
  Gui.new({
    parent = self.scheduleContainer,
    backgroundColor = Color.new(0.3, 0.3, 0.3, 1.0),
    border = { top = true, right = true, bottom = true, left = true },
    borderColor = Color.new(0.5, 0.5, 0.5, 1.0),
  })

  -- Task type headers
  for _, taskName in ipairs(taskNames) do
    Gui.new({
      parent = self.scheduleContainer,
      text = taskName,
      textColor = Color.new(1, 1, 1, 1),
      textAlign = "center",
      backgroundColor = Color.new(0.3, 0.3, 0.3, 1.0),
      border = { top = true, right = true, bottom = true, left = true },
      borderColor = Color.new(0.5, 0.5, 0.5, 1.0),
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
      textColor = Color.new(1, 1, 1, 1),
      textAlign = "center",
      backgroundColor = Color.new(0.3, 0.3, 0.3, 1.0),
      border = { top = true, right = true, bottom = true, left = true },
      borderColor = Color.new(0.5, 0.5, 0.5, 1.0),
      textSize = 10,
    })

    -- Task cells for this colonist
    for _, task in ipairs(taskTypes) do
      local schedule = EntityManager:getComponent(colonist, ComponentType.SCHEDULE)
      local isEnabled = schedule and schedule[task.value] or false

      Gui.new({
        parent = self.scheduleContainer,
        text = isEnabled and "✓" or "",
        textColor = Color.new(0, 1, 0, 1),
        textAlign = "center",
        backgroundColor = isEnabled and Color.new(0.2, 0.5, 0.2, 1.0) or Color.new(0.4, 0.4, 0.4, 1.0),
        border = { top = true, right = true, bottom = true, left = true },
        borderColor = Color.new(0.5, 0.5, 0.5, 1.0),
        textSize = 12,
        callback = function(cell)
          -- Toggle task assignment
          local currentSchedule = EntityManager:getComponent(colonist, ComponentType.SCHEDULE) or {}
          currentSchedule[task.value] = not currentSchedule[task.value]
          EntityManager:addComponent(colonist, ComponentType.SCHEDULE, currentSchedule)

          -- Update cell appearance
          local newEnabled = currentSchedule[task.value]
          cell.text = newEnabled and "✓" or ""
          cell.backgroundColor = newEnabled and Color.new(0.2, 0.5, 0.2, 1.0) or Color.new(0.4, 0.4, 0.4, 1.0)

          Logger:debug(string.format("Toggled %s for %s: %s", task.name, name, tostring(newEnabled)))
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
    self.window:updateOpacity(1)
    self.minimizeButton:updateText("-", false)
  else
    self.window:updateOpacity(0)
    self.minimizeButton:updateText("+", false)
    self.minimizeButton:updateOpacity(1)
  end
  self.minimized = not self.minimized
end

return BottomBar.init()
