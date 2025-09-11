local Color = require("game.utils.color")
local Gui = require("game.libs.MyGUI")
local enums = require("game.utils.enums")
local Positioning, FlexDirection, JustifyContent, AlignContent, AlignItems =
  enums.Positioning, enums.FlexDirection, enums.JustifyContent, enums.AlignContent, enums.AlignItems

---@class EscapeMenu
---@field visible boolean
local EscapeMenu = {}
EscapeMenu.__index = EscapeMenu

local instance

function EscapeMenu.init()
  if instance == nil then
    local self = setmetatable({}, EscapeMenu)
    self.visible = false
    self.menuWindow = nil
    instance = self
  end
  return instance
end

function EscapeMenu:draw()
  if self.visible then
    local w, h = love.window.getMode()
    if self.menuWindow == nil then
      local win = Gui.newWindow({
        x = 0,
        y = 0,
        w = w,
        h = h,
        title = "Escape Menu",
        border = { top = true, right = true, bottom = true, left = true },
        background = Color.new(0, 0, 0, 0.5),
        initVisible = true,
        textColor = Color.new(1, 1, 1, 1),
        positioning = Positioning.FLEX,
        flexDirection = FlexDirection.VERTICAL,
        justifyContent = JustifyContent.CENTER,
        alignItems = AlignContent.CENTER,
        gap = 10,
      })
      self.menuWindow = win
      -- Add buttons
      local closeBtn = Gui.Button.new({
        parent = win,
        w = 40,
        h = 40,
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
      local saveBtn = Gui.Button.new({
        parent = win,
        w = 80,
        h = 20,
        px = 0,
        py = 0,
        borderColor = Color.new(1, 1, 1, 1),
        text = "Save Game",
        callback = function()
          print("Saving game")
        end,
      })
      local loadBtn = Gui.Button.new({
        parent = win,
        w = 80,
        h = 20,
        px = 0,
        py = 0,
        borderColor = Color.new(1, 1, 1, 1),
        text = "Load Game",
        callback = function()
          print("Loading game")
        end,
      })
      local menuBtn = Gui.Button.new({
        parent = win,
        w = 80,
        h = 20,
        px = 0,
        py = 0,
        borderColor = Color.new(1, 1, 1, 1),
        text = "Main Menu",
        callback = function()
          Logger:debug("Returning to main menu")
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

return EscapeMenu.init()
