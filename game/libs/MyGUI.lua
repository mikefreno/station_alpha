local Color = require("game.utils.color")
local enums = require("game.utils.enums")
local FlexDirection = enums.FlexDirection
local JustifyContent = enums.JustifyContent
local AlignContent = enums.AlignContent
local AlignItems = enums.AlignItems
local Positioning = enums.Positioning
local TextAlign = enums.TextAlign

-- Simple GUI library for LOVE2D
-- Provides window and button creation, drawing, and click handling.

---@class Animation
---@field duration number
---@field start table{width:number,height:number}
---@field final table{width:number,height:number}
---@field elapsed number
local Animation = {}
Animation.__index = Animation

---@class AnimationProps
---@field duration number
---@field start table{width:number,height:number}
---@field final table{width:number,height:number}
local AnimationProps = {}

---@param props AnimationProps
function Animation.new(props)
  local self = setmetatable({}, Animation)
  self.duration = props.duration
  self.start = props.start
  self.final = props.final
  self.elapsed = 0
  return self
end

function Animation:update(dt)
  self.elapsed = self.elapsed + dt
  if self.elapsed >= self.duration then
    return true -- finished
  else
    return false
  end
end

function Animation:interpolate()
  local t = math.min(self.elapsed / self.duration, 1)
  return {
    width = self.start.width * (1 - t) + self.final.width * t,
    height = self.start.height * (1 - t) + self.final.height * t,
  }
end

local FONT_CACHE = {}

---@class Border
---@field top boolean?
---@field right boolean?
---@field bottom boolean?
---@field left boolean?

local Gui = {}

-- ====================
-- Window Object
-- ====================
---@class Window
---@field x number
---@field y number
---@field width number
---@field height number
---@field children table<integer, Button|Window>
---@field parent Window
---@field visible boolean
---@field border Border
---@field borderColor Color
---@field background Color
---@field prevGameSize {width:number, height:number}
---@field text string?
---@field textColor Color
---@field textAlign TextAlign
---@field gap number
---@field positioning Positioning -- default: ABSOLUTE
---@field flexDirection FlexDirection -- default: horizontal
---@field justifyContent JustifyContent -- default: start
---@field alignItems AlignItems -- default: start
---@field alignContent AlignContent -- default: start
local Window = {}
Window.__index = Window

---@class WindowProps
---@field x number
---@field y number
---@field w number
---@field h number
---@field border Border
---@field borderColor Color? -- default: black? -- default: none
---@field background Color?  --default: transparent
---@field gap number? -- default: 10
---@field text string? -- default: nil
---@field titleColor Color? -- default: black
---@field textAlign TextAlign?
---@field initVisible boolean? --default: `false`
---@field textColor Color? -- default: black
---@field positioning Positioning? -- default: ABSOLUTE
---@field flexDirection FlexDirection? -- default: HORIZONTAL
---@field justifyContent JustifyContent? -- default: FLEX_START
---@field alignItems AlignItems? -- default: STRETCH
---@field alignContent AlignContent? -- default: STRETCH
local WindowProps = {}

---@param props WindowProps
---@return Window
function Window.new(props)
  local self = setmetatable({}, Window)
  self.x = props.x
  self.y = props.y
  self.width = props.w or self:calculateAutoWidth()
  self.height = props.h or self:calculateAutoHeight()
  self.children = {}
  self.border = props.border
      and {
        top = props.border.top or false,
        right = props.border.right or false,
        bottom = props.border.bottom or false,
        left = props.border.left or false,
      }
    or {
      top = false,
      right = false,
      bottom = false,
      left = false,
    }

  self.background = props.background or Color.new(0, 0, 0, 0)
  self.borderColor = props.borderColor or Color.new(0, 0, 0, 1)
  self.textColor = props.textColor or Color.new(0, 0, 0, 1)
  self.visible = props.initVisible or true
  self.gap = props.gap or 10
  self.text = props.text
  self.textColor = props.textColor or Color.new(0, 0, 0, 1)
  self.textAlign = props.textAlign or TextAlign.START

  self.positioning = props.positioning or Positioning.ABSOLUTE
  if self.positioning == Positioning.FLEX then
    self.positioning = props.positioning
    self.justifyContent = props.justifyContent or JustifyContent.FLEX_START
    self.alignItems = props.alignItems or AlignItems.STRETCH
    self.alignContent = props.alignContent or AlignContent.STRETCH
  end

  local gw, gh = love.window.getMode()
  self.prevGameSize = { width = gw, height = gh }

  return self
end

---@return table
function Window:getBounds()
  return { x = self.x, y = self.y, width = self.width, height = self.height }
end

--- Add child to window
---@param child Button
function Window:addChild(child)
  child.parent = self
  table.insert(self.children, child)
  self:layoutChildren()
end

function Window:layoutChildren()
  if self.positioning == Positioning.ABSOLUTE then
    return
  end

  -- Calculate total size of children
  local totalSize = 0
  local childCount = #self.children

  if childCount == 0 then
    return
  end

  for _, child in ipairs(self.children) do
    if self.flexDirection == FlexDirection.HORIZONTAL then
      totalSize = totalSize + (child.width or 0)
    else
      totalSize = totalSize + (child.height or 0)
    end
  end

  -- Add gaps between children
  totalSize = totalSize + (childCount - 1) * self.gap

  -- Calculate available space
  local availableSpace = self.flexDirection == FlexDirection.HORIZONTAL and self.width or self.height
  local freeSpace = availableSpace - totalSize

  -- Calculate spacing based on self.justifyContent
  local spacing = 0
  if self.justifyContent == JustifyContent.FLEX_START then
    spacing = 0
  elseif self.justifyContent == JustifyContent.CENTER then
    spacing = freeSpace / 2
  elseif self.justifyContent == JustifyContent.FLEX_END then
    spacing = freeSpace
  elseif self.justifyContent == JustifyContent.SPACE_AROUND then
    spacing = freeSpace / (childCount + 1)
  elseif self.justifyContent == JustifyContent.SPACE_EVENLY then
    spacing = freeSpace / (childCount + 1)
  elseif self.justifyContent == JustifyContent.SPACE_BETWEEN then
    if childCount > 1 then
      spacing = freeSpace / (childCount - 1)
    else
      spacing = 0
    end
  end

  -- Position children
  local currentPos = spacing
  for _, child in ipairs(self.children) do
    if child.positioning == Positioning.ABSOLUTE then
      goto continue
    end
    if self.flexDirection == FlexDirection.VERTICAL then
      child.x = self.x + currentPos
      child.y = self.y

      -- Apply alignment to vertical axis (alignItems)
      if self.alignItems == AlignItems.FLEX_START then
        child.y = self.y
      elseif self.alignItems == AlignItems.CENTER then
        child.y = self.y + (self.height - (child.height or 0)) / 2
      elseif self.alignItems == AlignItems.FLEX_END then
        child.y = self.y + self.height - (child.height or 0)
      elseif self.alignItems == AlignItems.STRETCH then
        child.height = self.height
      end
      currentPos = currentPos + (child.width or 0) + self.gap
    else
      child.x = self.x
      child.y = self.y + currentPos
      -- Apply alignment to horizontal axis (alignItems)
      if self.alignItems == AlignItems.FLEX_START then
        child.x = self.x
      elseif self.alignItems == AlignItems.CENTER then
        child.x = self.x + (self.width - (child.width or 0)) / 2
      elseif self.alignItems == AlignItems.FLEX_END then
        child.x = self.x + self.width - (child.width or 0)
      elseif self.alignItems == AlignItems.STRETCH then
        child.width = self.width
      end

      currentPos = currentPos + (child.height or 0) + self.gap
    end
    ::continue::
  end
end

--- Destroy window and its children
function Window:destroy()
  -- Remove from global windows list
  for i, win in ipairs(Gui.windows) do
    if win == self then
      table.remove(Gui.windows, i)
      break
    end
  end

  -- Destroy all children
  for _, child in ipairs(self.children) do
    child:destroy()
  end

  -- Clear children table
  self.children = {}

  -- Clear parent reference
  if self.parent then
    self.parent = nil
  end

  -- Clear animation reference
  self.animation = nil
end

--- Draw window and its children
function Window:draw()
  if not self.visible then
    return
  end
  love.graphics.setColor(self.background:toRGBA())
  love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
  love.graphics.setColor(0, 0, 0)
  -- Draw borders based on border property
  love.graphics.setColor(self.borderColor:toRGBA())
  if self.border.top then
    love.graphics.line(self.x, self.y, self.x + self.width, self.y)
  end
  if self.border.bottom then
    love.graphics.line(self.x, self.y + self.height, self.x + self.width, self.y + self.height)
  end
  if self.border.left then
    love.graphics.line(self.x, self.y, self.x, self.y + self.height)
  end
  if self.border.right then
    love.graphics.line(self.x + self.width, self.y, self.x + self.width, self.y + self.height)
  end
  for _, child in ipairs(self.children) do
    child:draw()
  end
end

--- Update window (propagate to children)
---@param dt number
function Window:update(dt)
  for _, child in ipairs(self.children) do
    child:update(dt)
  end
end

--- Resize window and its children based on game window size change
---@param newGameWidth number
---@param newGameHeight number
function Window:resize(newGameWidth, newGameHeight)
  local prevW = self.prevGameSize.width
  local prevH = self.prevGameSize.height
  local ratioW = newGameWidth / prevW
  local ratioH = newGameHeight / prevH

  -- Create animation for resizing
  if not self.animation then
    self.animation = Animation.new({
      duration = ratioW,
      start = { width = self.width, height = self.height },
      final = { width = self.width * ratioW, height = self.height * ratioH },
    })
  else
    self.animation:update(0) -- reset elapsed
  end

  -- Update window size using animation interpolation
  local anim = self.animation:interpolate()
  self.width = anim.width
  self.height = anim.height
  self.x = self.x * ratioW
  self.y = self.y * ratioH

  -- Update children positions and sizes
  for _, child in ipairs(self.children) do
    child:resize(ratioW, ratioH)
  end

  -- Re-layout children after resizing
  self:layoutChildren()

  self.prevGameSize.width = newGameWidth
  self.prevGameSize.height = newGameHeight
end

--- Calculate auto width based on children
function Window:calculateAutoWidth()
  if not self.children or #self.children == 0 then
    self.width = 200 -- default minimum width
    return
  end

  local maxWidth = 0
  for _, child in ipairs(self.children) do
    local childWidth = child.width or 100
    local childX = child.x or 0
    local totalWidth = childX + childWidth

    if totalWidth > maxWidth then
      maxWidth = totalWidth
    end
  end

  -- Add some padding for window edges and title
  self.width = maxWidth + 20
end

--- Calculate auto height based on children
function Window:calculateAutoHeight()
  if not self.children or #self.children == 0 then
    self.height = 150 -- default minimum height
    return
  end

  local maxHeight = 0
  for _, child in ipairs(self.children) do
    local childHeight = child.height or 30
    local childY = child.y or 0
    local totalHeight = childY + childHeight

    if totalHeight > maxHeight then
      maxHeight = totalHeight
    end
  end

  -- Add some padding for window edges and title
  self.height = maxHeight + 20
end

--- Get title position based on placement
--- NOTE: This will be updated and replaced in future, with the title having a section dedicated to it
function Window:getTitlePosition()
  local font = love.graphics.getFont()
  local titleWidth = font:getWidth(self.title)
  local titleHeight = font:getHeight()

  -- Default to TOP_LEFT if no placement specified
  local placement = self.titlePlacement or 1

  if placement == 1 then -- TOP_LEFT
    return self.x + 10, self.y + 5
  elseif placement == 2 then -- TOP_CENTER
    return self.x + (self.width - titleWidth) / 2, self.y + 5
  elseif placement == 3 then -- TOP_RIGHT
    return self.x + self.width - titleWidth - 10, self.y + 5
  elseif placement == 4 then -- CENTER_LEFT
    return self.x + 10, self.y + (self.height - titleHeight) / 2
  elseif placement == 5 then -- CENTER_RIGHT
    return self.x + self.width - titleWidth - 10, self.y + (self.height - titleHeight) / 2
  elseif placement == 6 then -- CENTER_CENTER
    return self.x + (self.width - titleWidth) / 2, self.y + (self.height - titleHeight) / 2
  elseif placement == 7 then -- BOTTOM_LEFT
    return self.x + 10, self.y + self.height - titleHeight - 5
  elseif placement == 8 then -- BOTTOM_CENTER
    return self.x + (self.width - titleWidth) / 2, self.y + self.height - titleHeight - 5
  elseif placement == 9 then -- BOTTOM_RIGHT
    return self.x + self.width - titleWidth - 10, self.y + self.height - titleHeight - 5
  else
    return self.x + 10, self.y + 5 -- fallback to TOP_LEFT
  end
end

---@class Button
---@field x number
---@field y number
---@field width number
---@field height number
---@field px number
---@field py number
---@field text string
---@field border Border
---@field borderColor Color?
---@field background Color
---@field parent Window
---@field callback function
---@field textColor Color?
---@field _touchPressed boolean
---@field positioning Positioning --default: ABSOLUTE (checks parent first)
local Button = {}
Button.__index = Button

---@class ButtonProps
---@field parent Window? -- optional
---@field x number?
---@field y number?
---@field w number?
---@field h number?
---@field px number?
---@field py number?
---@field text string?
---@field callback function?
---@field background Color?
---@field border Border?
---@field borderColor Color? -- default: black
---@field textColor Color? -- default: black,
---@field positioning Positioning? --default: ABSOLUTE (checks parent first)
local ButtonProps = {}

---@param props ButtonProps
---@return Button
function Button.new(props)
  local self = setmetatable({}, Button)
  self.parent = props.parent
  self.x = props.x or 0
  self.y = props.y or 0
  self.px = props.px or 0
  self.py = props.py or 0
  self.width = props.w or self:calculateTextWidth(props.text) + props.px
  self.height = props.h or self:calculateTextHeight() + props.py
  self.text = props.text or ""
  self.border = props.border
      and {
        top = props.border.top or true,
        right = props.border.right or true,
        bottom = props.border.bottom or true,
        left = props.border.left or true,
      }
    or {
      top = true,
      right = true,
      bottom = true,
      left = true,
    }
  self.borderColor = props.borderColor or Color.new(0, 0, 0, 1)
  self.textColor = props.textColor
  self.background = props.background or Color.new(0, 0, 0, 0)

  self.positioning = props.positioning or props.parent.positioning

  self.callback = props.callback or function() end
  self._pressed = false
  self._touchPressed = false

  props.parent:addChild(self)
  return self
end

function Button:bounds()
  return { x = self.parent.x + self.x, y = self.parent.y + self.y, width = self.width, height = self.height }
end

---comment
---@param ratioW number?
---@param ratioH number?
function Button:resize(ratioW, ratioH)
  self.x = self.x * (ratioW or 1)
  self.y = self.y * (ratioH or 1)
  self.width = self.width * (ratioW or 1)
  self.height = self.height * (ratioH or 1)
end

---@param newText string
---@param autoresize boolean? --default: false
function Button:updateText(newText, autoresize)
  self.text = newText or self.text
  if autoresize then
    self.width = self:calculateTextWidth() + self.px
    self.height = self:calculateTextHeight() + self.py
  end
end

function Button:draw()
  love.graphics.setColor(self.background:toRGBA())
  love.graphics.rectangle("fill", self.parent.x + self.x, self.parent.y + self.y, self.width, self.height)
  love.graphics.setColor(0, 0, 0)
  -- Draw borders based on border property
  love.graphics.setColor(self.borderColor:toRGBA())
  if self.border.top then
    love.graphics.line(
      self.parent.x + self.x,
      self.parent.y + self.y,
      self.parent.x + self.x + self.width,
      self.parent.y + self.y
    )
  end
  if self.border.bottom then
    love.graphics.line(
      self.parent.x + self.x,
      self.parent.y + self.y + self.height,
      self.parent.x + self.x + self.width,
      self.parent.y + self.y + self.height
    )
  end
  if self.border.left then
    love.graphics.line(
      self.parent.x + self.x,
      self.parent.y + self.y,
      self.parent.x + self.x,
      self.parent.y + self.y + self.height
    )
  end
  if self.border.right then
    love.graphics.line(
      self.parent.x + self.x + self.width,
      self.parent.y + self.y,
      self.parent.x + self.x + self.width,
      self.parent.y + self.y + self.height
    )
  end

  local textColor = self.textColor or self.parent.textColor
  love.graphics.setColor(textColor:toRGBA())
  local tx = self.parent.x + self.x + (self.width - self:calculateTextWidth()) / 2
  local ty = self.parent.y + self.y + (self.height - self:calculateTextHeight()) / 3
  love.graphics.print(self.text, tx, ty)
end

--- Calculate text width for button
---@return number
function Button:calculateTextWidth(text)
  local font = love.graphics.getFont()

  local width = font:getWidth(self.text or text or "")
  return width
end

---@return number
function Button:calculateTextHeight()
  local font = love.graphics.getFont()

  local height = font:getHeight()
  return height
end

--- Check if mouse is over button and handle click
---@param dt number
function Button:update(dt)
  local mx, my = love.mouse.getPosition()
  local bx = self.parent.x + self.x
  local by = self.parent.y + self.y
  if mx >= bx and mx <= bx + self.width and my >= by and my <= by + self.height then
    if love.mouse.isDown(1) then
      -- set pressed flag
      self._pressed = true
    elseif not love.mouse.isDown(1) and self._pressed then
      self.callback(self)
      self._pressed = false
    end
  else
    self._pressed = false
  end

  local touches = love.touch.getTouches()
  for _, id in ipairs(touches) do
    local tx, ty = love.touch.getPosition(id)
    if tx >= bx and tx <= bx + self.width and ty >= by and ty <= by + self.height then
      self._touchPressed[id] = true
    elseif self._touchPressed[id] then
      self.callback(self)
      self._touchPressed[id] = false
    end
  end
end

--- Destroy button
function Button:destroy()
  -- Remove from parent's children list
  if self.parent then
    for i, child in ipairs(self.parent.children) do
      if child == self then
        table.remove(self.parent.children, i)
        break
      end
    end
    self.parent = nil
  end
  -- Clear callback reference
  self.callback = nil
  -- Clear touchPressed references
  self._touchPressed = nil
end

--- Global GUI manager
Gui.windows = {}

---@param props WindowProps
---@return Window
function Gui.newWindow(props)
  local win = Window.new(props)
  table.insert(Gui.windows, win)
  return win
end

function Gui.resize()
  local newWidth, newHeight = love.window.getMode()
  for _, win in ipairs(Gui.windows) do
    win:resize(newWidth, newHeight)
  end
end

function Gui.draw()
  for _, win in ipairs(Gui.windows) do
    win:draw()
  end
end

function Gui.update(dt)
  for _, win in ipairs(Gui.windows) do
    win:update(dt)
  end
end

--- Destroy all windows and their children
function Gui.destroy()
  for _, win in ipairs(Gui.windows) do
    win:destroy()
  end
  Gui.windows = {}
end

Gui.Button = Button
return Gui
