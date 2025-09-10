-- Simple GUI library for LOVE2D
-- Provides window and button creation, drawing, and click handling.

local Gui = {}

-- ====================
-- Window Object
-- ====================
---@class Window
---@field x number
---@field y number
---@field width number
---@field height number
---@field children table<integer, Button>
---@field title string
---@field prevGameSize {width:number, height:number}
local Window = {}
Window.__index = Window

---@param x number
---@param y number
---@param w number
---@param h number
---@param title string?
---@return Window
function Window.new(x, y, w, h, title)
    local self = setmetatable({}, Window)
    self.x = x
    self.y = y
    self.width = w or self:calculateAutoWidth()
    self.height = h or self:calculateAutoHeight()

    self.children = {}
    self.title = title or ""
    local gw, gh = love.window.getMode()
    self.prevGameSize = { width = gw, height = gh }

    return self
end

---@return table
function Window:getBounds() return { x = self.x, y = self.y, width = self.width, height = self.height } end

--- Add child to window
---@param child Button
function Window:addChild(child) table.insert(self.children, child) end

--- Draw window and its children
function Window:draw()
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    if self.title ~= "" then love.graphics.print(self.title, self.x + 10, self.y + 5) end
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
    -- Update window size
    self.width = self.width * ratioW
    self.height = self.height * ratioH
    self.x = self.x * ratioW
    self.y = self.y * ratioH
    -- Update children positions and sizes
    for _, child in ipairs(self.children) do
        child:resize(ratioW, ratioH)
    end
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

        if totalWidth > maxWidth then maxWidth = totalWidth end
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

        if totalHeight > maxHeight then maxHeight = totalHeight end
    end

    -- Add some padding for window edges and title
    self.height = maxHeight + 20
end

--- Button object
---@class Button
---@field x number
---@field y number
---@field width number
---@field height number
---@field px number
---@field py number
---@field text string
---@field parent Window
---@field callback function
local Button = {}
Button.__index = Button

---@param parent Window
---@param x number
---@param y number
---@param w number?
---@param h number?
---@param px number?
---@param py number?
---@param text string
---@param callback function
---@return Button
function Button.new(parent, x, y, w, h, px, py, text, callback)
    local self = setmetatable({}, Button)
    self.parent = parent
    self.x = x
    self.y = y
    self.px = px or 0
    self.py = py or 0
    self.width = w or self:calculateTextWidth(text) + px
    self.height = h or self:calculateTextHeight() + py
    self.text = text or ""
    self.callback = callback or function() end
    self._pressed = false
    self._touchPressed = false

    parent:addChild(self)
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
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("fill", self.parent.x + self.x, self.parent.y + self.y, self.width, self.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.parent.x + self.x, self.parent.y + self.y, self.width, self.height)
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
            -- touch pressed flag
            self._touchPressed = true
        elseif not love.touch.isDown(id) and self._touchPressed then
            self.callback(self)
            self._touchPressed = false
        end
    end
end

--- Global GUI manager
Gui.windows = {}

---@param x number
---@param y number
---@param w number
---@param h number
---@param title string?
---@return Window
function Gui.newWindow(x, y, w, h, title)
    local win = Window.new(x, y, w, h, title)
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

Gui.Button = Button
return Gui
