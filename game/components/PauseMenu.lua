local ZIndexing = require("utils.enums").ZIndexing
local FlexLove = require("libs.FlexLove")
local enums = FlexLove.enums
local Gui = FlexLove.GUI
local Color = FlexLove.Color
local Positioning, FlexDirection, JustifyContent, AlignContent, AlignItems, TextAlign, TextSize =
  enums.Positioning,
  enums.FlexDirection,
  enums.JustifyContent,
  enums.AlignContent,
  enums.AlignItems,
  enums.TextAlign,
  enums.TextSize
local EventBus = require("systems.EventBus")

---@class PauseMenu
---@field visible boolean
---@field window Element
local PauseMenu = {}
PauseMenu.__index = PauseMenu

local instance

function PauseMenu.init()
  if instance == nil then
    local self = setmetatable({}, PauseMenu)
    self.visible = false
    self.window = nil
    instance = self
  end
  return instance
end

function PauseMenu:toggle()
  self.visible = not self.visible
  if self.visible then
    self.window = Gui.new({
      x = 0,
      y = 0,
      z = ZIndexing.PauseMenu,
      width = "100%",
      height = "100%",
      themeComponent = "card",
      textColor = Color.new(1, 1, 1, 1),
      positioning = Positioning.FLEX,
      flexDirection = FlexDirection.VERTICAL,
      justifyContent = JustifyContent.CENTER,
      alignItems = AlignItems.CENTER,
      padding = { vertical = "10%", horizontal = "10%" },
      backgroundColor = Color.new(0, 0, 0, 0.8),
      gap = 10,
    })

    Gui.new({
      parent = self.window,
      text = "Pause Menu",
      margin = { top = "-15vh", bottom = "15vh" },
      padding = { horizontal = 24, vertical = 16 },
      textAlign = TextAlign.CENTER,
      textSize = "4xl",
    })
    Gui.new({
      parent = self.window,
      x = "4%",
      y = "4%",
      themeComponent = "button",
      width = "4vw",
      height = "4vw",
      padding = { horizontal = 12, vertical = 12 },
      positioning = Positioning.ABSOLUTE,
      text = "X",
      textSize = "2xl",
      textAlign = "center",
      callback = function(_, event)
        if event.type == "release" then
          self:toggle()
        end
      end,
    })
    Gui.new({
      parent = self.window,
      themeComponent = "button",
      text = "Settings",
      textAlign = "center",
      width = 160,
      height = 40,
      padding = { horizontal = 12, vertical = 8 },
      callback = function(_, event)
        if event.type == "release" then
          -- TODO: implement Settings screen function
          Logger:error("Settings screen not yet implemented")
        end
      end,
    })
    Gui.new({
      parent = self.window,
      textAlign = "center",
      themeComponent = "button",
      width = 160,
      height = 40,
      padding = { horizontal = 12, vertical = 8 },
      text = "Save Game",
      callback = function(_, event)
        if event.type == "release" then
          -- TODO: implement saving function
          Logger:error("Save function not yet implemented")
        end
      end,
    })
    Gui.new({
      parent = self.window,
      themeComponent = "button",
      text = "Load Game",
      textAlign = "center",
      width = 160,
      height = 40,
      padding = { horizontal = 12, vertical = 8 },
      callback = function(_, event)
        if event.type == "release" then
          -- TODO: implement loading function
          Logger:error("Loading function not yet implemented")
        end
      end,
    })
    Gui.new({
      parent = self.window,
      themeComponent = "button",
      text = "Main Menu",
      textAlign = "center",
      width = 160,
      height = 40,
      padding = { horizontal = 12, vertical = 8 },
      callback = function(_, event)
        if event.type == "release" then
          -- TODO: implement main menu function
          Logger:error("Main menu not yet implemented")
        end
      end,
    })
    Gui.new({
      parent = self.window,
      themeComponent = "button",
      text = "Quit Game",
      textAlign = "center",
      width = 160,
      height = 40,
      padding = { horizontal = 12, vertical = 8 },
      callback = function(_, event)
        if event.type == "release" then
          love.event.quit()
        end
      end,
    })
  else
    self.window:destroy()
    self.window = nil
  end

  -- Emit event when pause state changes
  EventBus:emit("game_paused", { paused = self.visible })
end

return PauseMenu.init()
