local Color = require("game.utils.color")
local Gui = require("game.libs.MyGUI")
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
        love.graphics.setColor(0, 0, 0, 0.5)
        local w, h = love.window.getMode()
        love.graphics.rectangle("fill", 0, 0, w, h)
        -- Create or update the escape menu window if not already created
        if self.menuWindow == nil then
            local win = Gui.newWindow({
                x = 0,
                y = 0,
                w = w,
                h = h,
                title = "Escape Menu",
                border = { top = true, right = true, bottom = true, left = true },
                background = nil,
                initVisible = true,
                textColor = Color.new(1, 1, 1, 1),
                flexDirection = "vertical",
                justifyContent = "center",
                alignItems = "center",
                gap = 10,
            })
            self.menuWindow = win
            -- Add buttons
            local closeBtn = Gui.Button.new({
                parent = win,
                w = 20,
                h = 20,
                px = 0,
                py = 0,
                text = "X",
                callback = function() self.visible = false end,
            })
            local saveBtn = Gui.Button.new({
                parent = win,
                w = 80,
                h = 20,
                px = 0,
                py = 0,
                borderColor = Color.new(1, 1, 1, 1),
                text = "Save Game",
                callback = function() print("Saving game") end,
            })
            local loadBtn = Gui.Button.new({
                parent = win,
                w = 80,
                h = 20,
                px = 0,
                py = 0,
                borderColor = Color.new(1, 1, 1, 1),
                text = "Load Game",
                callback = function() print("Loading game") end,
            })
            local menuBtn = Gui.Button.new({
                parent = win,
                w = 80,
                h = 20,
                px = 0,
                py = 0,
                borderColor = Color.new(1, 1, 1, 1),
                text = "Main Menu",
                callback = function() Logger:debug("Returning to main menu") end,
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
