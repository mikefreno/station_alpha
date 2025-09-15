local FlexLove = require("game.libs.FlexLove")
local Gui = FlexLove.GUI
local Color = FlexLove.Color

---@class AnimDemo
---@field window Window
---@field button Button
---@field fadeButton Button
---@field scaleButton Button
local AnimDemo = {}
AnimDemo.__index = AnimDemo

function AnimDemo:init()
  local self = setmetatable({}, AnimDemo)
  
  local w, h = love.window.getMode()
  
  -- Create a demo window
  self.window = Gui.Window.new({
    x = 100,
    y = 100,
    z = 10,
    w = 300,
    h = 200,
    background = Color.new(0.1, 0.1, 0.3, 0.8),
    border = { top = true, bottom = true, left = true, right = true },
    borderColor = Color.new(0.7, 0.7, 0.7, 1)
  })
  
  -- Create a demo button
  self.button = Gui.Button.new({
    parent = self.window,
    x = 20,
    y = 20,
    w = 100,
    h = 40,
    text = "Animate Me",
    background = Color.new(0.2, 0.6, 0.9, 0.8),
    textColor = Color.new(1, 1, 1),
    borderColor = Color.new(0.4, 0.8, 1, 1),
    callback = function()
      -- Create a scale animation
      local scaleAnim = Gui.Animation.scale(2, { width = 100, height = 40 }, { width = 150, height = 60 })
      scaleAnim:apply(self.button)
    end,
  })
  
  -- Create a fade button
  self.fadeButton = Gui.Button.new({
    parent = self.window,
    x = 20,
    y = 80,
    w = 100,
    h = 40,
    text = "Fade",
    background = Color.new(0.2, 0.9, 0.6, 0.8),
    textColor = Color.new(1, 1, 1),
    borderColor = Color.new(0.4, 1, 0.8, 1),
    callback = function()
      -- Create a fade animation
      local fadeAnim = Gui.Animation.fade(1, 0.8, 0.2)
      fadeAnim:apply(self.window)
    end,
  })
  
  -- Create a scale button
  self.scaleButton = Gui.Button.new({
    parent = self.window,
    x = 20,
    y = 140,
    w = 100,
    h = 40,
    text = "Scale",
    background = Color.new(0.9, 0.6, 0.2, 0.8),
    textColor = Color.new(1, 1, 1),
    borderColor = Color.new(1, 0.8, 0.4, 1),
    callback = function()
      -- Create a scale animation
      local scaleAnim = Gui.Animation.scale(1.5, { width = 100, height = 40 }, { width = 200, height = 80 })
      scaleAnim:apply(self.button)
    end,
  })
  
  return self
end

function AnimDemo:update(dt)
  -- Update the window's animation if exists (handled by Window.update)
  self.window:update(dt)
end

function AnimDemo:draw()
  self.window:draw()
end

return AnimDemo:init()