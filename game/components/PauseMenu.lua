local ZIndexing = require("game.utils.enums").ZIndexing
local FlexLove = require("game.libs.FlexLove")
local enums = FlexLove.enums
local Gui = FlexLove.GUI
local Color = FlexLove.Color
local Positioning, FlexDirection, JustifyContent, AlignContent, AlignItems, TextAlign =
  enums.Positioning, enums.FlexDirection, enums.JustifyContent, enums.AlignContent, enums.AlignItems, enums.TextAlign

---@class PauseMenu
---@field visible boolean
---@field window Window
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
    local w, h = love.window.getMode()
    Logger:debug(w .. "," .. h)
    self.window = Gui.Window.new({
      x = 0,
      y = 0,
      z = ZIndexing.PauseMenu,
      w = w,
      h = h,
      border = { top = true, right = true, bottom = true, left = true },
      background = Color.new(0, 0, 0, 0.5),
      textColor = Color.new(1, 1, 1, 1),
      positioning = Positioning.FLEX,
      flexDirection = FlexDirection.VERTICAL,
      justifyContent = JustifyContent.CENTER,
      alignItems = AlignContent.CENTER,
      gap = 10,
    })
    Gui.Window.new({
      parent = self.window,
      text = "Pause Menu",
      textAlign = TextAlign.CENTER,
      textSize = 40,
    })
    -- Add buttons
    Gui.Button.new({
      parent = self.window,
      x = 40,
      y = 40,
      px = 0,
      py = 0,
      borderColor = Color.new(1, 1, 1, 1),
      positioning = Positioning.ABSOLUTE,
      text = "X",
      textSize = 40,
      callback = function()
        self:toggle()
      end,
    })
    Gui.Button.new({
      parent = self.window,
      w = 80,
      h = 20,
      px = 0,
      py = 0,
      borderColor = Color.new(1, 1, 1, 1),
      text = "Settings",
      callback = function()
        -- TODO: implement Settings screen function
        Logger:error("Settings screen not yet implemented")
      end,
    })
    Gui.Button.new({
      parent = self.window,
      w = 80,
      h = 20,
      px = 0,
      py = 0,
      borderColor = Color.new(1, 1, 1, 1),
      text = "Save Game",
      callback = function()
        -- TODO: implement saving function
        Logger:error("Save function not yet implemented")
      end,
    })
    Gui.Button.new({
      parent = self.window,
      w = 80,
      h = 20,
      px = 0,
      py = 0,
      borderColor = Color.new(1, 1, 1, 1),
      text = "Load Game",
      callback = function()
        -- TODO: implement loading function
        Logger:error("Loading function not yet implemented")
      end,
    })
    Gui.Button.new({
      parent = self.window,
      w = 80,
      h = 20,
      px = 0,
      py = 0,
      borderColor = Color.new(1, 1, 1, 1),
      text = "Main Menu",
      callback = function()
        -- TODO: implement main menu function
        Logger:error("Main menu not yet implemented")
      end,
    })
  else
    self.window:destroy()
    self.window = nil
  end
end

return PauseMenu.init()
