local Color = require("game.utils.color")
local Gui = require("game.libs.MyGUI")
local enums = require("game.utils.enums")
local Positioning, FlexDirection, JustifyContent, AlignContent, AlignItems, TextAlign =
  enums.Positioning, enums.FlexDirection, enums.JustifyContent, enums.AlignContent, enums.AlignItems, enums.TextAlign

---@class PauseMenu
---@field visible boolean
local PauseMenu = {}
PauseMenu.__index = PauseMenu

local instance

function PauseMenu.init()
  if instance == nil then
    local self = setmetatable({}, PauseMenu)
    self.visible = false
    self.menuWindow = nil
    instance = self
  end
  return instance
end

function PauseMenu:draw()
  if self.visible then
    local w, h = love.window.getMode()
    if self.menuWindow == nil then
      self.menuWindow = Gui.Window.new({
        x = 0,
        y = 0,
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
      Gui.Window.new({ parent = self.menuWindow, text = "Pause Menu", textAlign = TextAlign.CENTER })
      -- Add buttons
      Gui.Button.new({
        parent = self.menuWindow,
        x = 40,
        y = 40,
        px = 0,
        py = 0,
        borderColor = Color.new(1, 1, 1, 1),
        positioning = Positioning.ABSOLUTE,
        text = "X",
        callback = function()
          self.visible = false
        end,
      })
      Gui.Button.new({
        parent = self.menuWindow,
        x = w - 40,
        y = 40,
        px = 0,
        borderColor = Color.new(1, 1, 1, 1),
        positioning = Positioning.ABSOLUTE,
        text = "settings",
        callback = function()
          self.visible = false
        end,
      })
      Gui.Button.new({
        parent = self.menuWindow,
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
        parent = self.menuWindow,
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
        parent = self.menuWindow,
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
    end
    self.menuWindow:draw()
  else
    -- Destroy the menu window if it exists and is not visible
    if self.menuWindow ~= nil then
      self.menuWindow:destroy()
      self.menuWindow = nil
    end
  end
end

return PauseMenu.init()
