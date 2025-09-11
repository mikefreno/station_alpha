local Color = require("game.utils.color")
local enums = require("game.utils.enums")
local Placement = enums.Placement
-- Simple GUI library for LOVE2D
-- Provides window and button creation, drawing, and click handling.

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
---@field title string
---@field titlePlacement Placement?
---@field border Border
---@field borderColor Color? -- default: black
---@field background Color?
---@field textColor Color
---@field prevGameSize {width:number, height:number}
local Window = {}
Window.__index = Window

---@class WindowProps
---@field x number
---@field y number
---@field w number
---@field h number
---@field title string?
---@field titlePlacement Placement? -- default: TOP_LEFT
---@field border Border
---@field borderColor Color? -- default: black? -- default: none
---@field background Color?  --default: transparent
---@field layout string? -- default: horizontal
---@field justifyContent string? -- default: start
---@field alignItems string? -- default: start
---@field initVisible boolean? --default: `false`
---@field textColor Color? -- default: black
---@field flexDirection string? -- default: horizontal
---@field flexWrap string? -- default: none
---@field gap number? -- default: 10
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
    self.title = props.title or ""
    self.titlePlacement = props.titlePlacement or Placement.TOP_LEFT
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
    local gw, gh = love.window.getMode()
    self.prevGameSize = { width = gw, height = gh }

    return self
end

---@return table
function Window:getBounds() return { x = self.x, y = self.y, width = self.width, height = self.height } end

--- Add child to window
---@param child Button
function Window:addChild(child)
    child.parent = self
    table.insert(self.children, child)

    local numChildren = #self.children

    if self.flexDirection == "horizontal" then
        -- compute total width of all children including padding between them
        local totalWidth = 0
        for _, c in ipairs(self.children) do
            totalWidth = totalWidth + (c.width or 100)
        end
        local paddingBetween = (numChildren - 1) * (self.gap or 10)

        totalWidth = totalWidth + paddingBetween

        -- determine starting x based on justifyContent
        local startX
        if self.justifyContent == "start" then
            startX = self.x + 10
        elseif self.justifyContent == "center" then
            startX = self.x + (self.width - totalWidth) / 2
        elseif self.justifyContent == "end" then
            startX = self.x + self.width - totalWidth - 10
        else
            startX = self.x + 10 -- default
        end

        local currentX = startX
        for _, c in ipairs(self.children) do
            c.x = currentX
            currentX = currentX + (c.width or 100) + 10
        end

        -- alignItems vertical
        if self.alignItems == "start" then
            for _, c in ipairs(self.children) do
                c.y = self.y + 10
            end
        elseif self.alignItems == "center" then
            local totalHeight = 0
            for _, c in ipairs(self.children) do
                totalHeight = totalHeight + (c.height or 30)
            end
            local paddingBetweenH = (numChildren - 1) * 10
            totalHeight = totalHeight + paddingBetweenH
            local startY = self.y + (self.height - totalHeight) / 2
            for _, c in ipairs(self.children) do
                c.y = startY
                startY = startY + (c.height or 30) + 10
            end
        elseif self.alignItems == "end" then
            local totalHeight = 0
            for _, c in ipairs(self.children) do
                totalHeight = totalHeight + (c.height or 30)
            end
            local paddingBetweenH = (numChildren - 1) * 10
            totalHeight = totalHeight + paddingBetweenH
            local startY = self.y + self.height - totalHeight - 10
            for _, c in ipairs(self.children) do
                c.y = startY
                startY = startY + (c.height or 30) + 10
            end
        else
            for _, c in ipairs(self.children) do
                c.y = self.y + 10
            end
        end
    elseif self.flexDirection == "vertical" then
        -- compute total height of all children including padding between them
        local totalHeight = 0
        for _, c in ipairs(self.children) do
            totalHeight = totalHeight + (c.height or 30)
        end
        local paddingBetween = (numChildren - 1) * 10

        totalHeight = totalHeight + paddingBetween

        -- determine starting y based on justifyContent
        local startY
        if self.justifyContent == "start" then
            startY = self.y + 10
        elseif self.justifyContent == "center" then
            startY = self.y + (self.height - totalHeight) / 2
        elseif self.justifyContent == "end" then
            startY = self.y + self.height - totalHeight - 10
        else
            startY = self.y + 10 -- default
        end

        local currentY = startY
        for _, c in ipairs(self.children) do
            c.y = currentY
            currentY = currentY + (c.height or 30) + 10
        end

        -- alignItems horizontal
        if self.alignItems == "start" then
            for _, c in ipairs(self.children) do
                c.x = self.x + 10
            end
        elseif self.alignItems == "center" then
            local totalWidth = 0
            for _, c in ipairs(self.children) do
                totalWidth = totalWidth + (c.width or 100)
            end
            local paddingBetweenW = (numChildren - 1) * 10
            totalWidth = totalWidth + paddingBetweenW
            local startX = self.x + (self.width - totalWidth) / 2
            for _, c in ipairs(self.children) do
                c.x = startX
                startX = startX + (c.width or 100) + 10
            end
        elseif self.alignItems == "end" then
            local totalWidth = 0
            for _, c in ipairs(self.children) do
                totalWidth = totalWidth + (c.width or 100)
            end
            local paddingBetweenW = (numChildren - 1) * 10
            totalWidth = totalWidth + paddingBetweenW
            local startX = self.x + self.width - totalWidth - 10
            for _, c in ipairs(self.children) do
                c.x = startX
                startX = startX + (c.width or 100) + 10
            end
        else
            for _, c in ipairs(self.children) do
                c.x = self.x + 10
            end
        end
    else
        -- default: no layout, keep as is
    end
end

--- Draw window and its children
function Window:draw()
    if not self.visible then return end
    love.graphics.setColor(self.background:toRGBA())
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(0, 0, 0)
    -- Draw borders based on border property
    love.graphics.setColor(self.borderColor:toRGBA())
    if self.border.top then love.graphics.line(self.x, self.y, self.x + self.width, self.y) end
    if self.border.bottom then
        love.graphics.line(self.x, self.y + self.height, self.x + self.width, self.y + self.height)
    end
    if self.border.left then love.graphics.line(self.x, self.y, self.x, self.y + self.height) end
    if self.border.right then
        love.graphics.line(self.x + self.width, self.y, self.x + self.width, self.y + self.height)
    end
    if self.title ~= "" then
        local tx, ty = self:getTitlePosition()
        love.graphics.setColor(self.textColor:toRGBA())
        love.graphics.print(self.title, tx, ty)
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
    -- Update window size
    self.width = self.width * ratioW
    self.height = self.height * ratioH
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

--- Get title position based on placement
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
local Button = {}
Button.__index = Button

---@class ButtonProps
---@field parent Window? -- optional
---@field x number
---@field y number
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
local ButtonProps = {}

---@param props ButtonProps
---@return Button
function Button.new(props)
    local self = setmetatable({}, Button)
    self.parent = props.parent
    self.x = props.x
    self.y = props.y
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

Gui.Button = Button
return Gui
