local Gui = require("libs.MyGUI")
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
        -- Dim all other windows by setting their visibility to false
        --for _, win in ipairs(Gui.windows) do
        --win.visible = false
        --end
        -- Draw dimming overlay
        love.graphics.setColor(0, 0, 0, 0.5)
        local w, h = love.window.getMode()
        love.graphics.rectangle("fill", 0, 0, w, h)
        -- Create or update the escape menu window if not already created
        if self.menuWindow == nil then
            local props = {
                x = 0,
                y = 0,
                w = w,
                h = h,
                title = "Escape Menu",
                border = { top = true, right = true, bottom = true, left = true },
                background = nil,
                initVisible = true,
            }
            local win = Gui.newWindow(props)
            self.menuWindow = win
            -- Add buttons
            local closeBtn = Gui.Button.new({
                parent = win,
                x = 10,
                y = 10,
                w = 20,
                h = 20,
                px = 0,
                py = 0,
                text = "X",
                callback = function() self.visible = false end,
            })
            local saveBtn = Gui.Button.new({
                parent = win,
                x = 10,
                y = 40,
                w = 80,
                h = 20,
                px = 0,
                py = 0,
                text = "Save Game",
                callback = function() print("Saving game") end,
            })
            local loadBtn = Gui.Button.new({
                parent = win,
                x = 10,
                y = 70,
                w = 80,
                h = 20,
                px = 0,
                py = 0,
                text = "Load Game",
                callback = function() print("Loading game") end,
            })
            local menuBtn = Gui.Button.new({
                parent = win,
                x = 10,
                y = 100,
                w = 80,
                h = 20,
                px = 0,
                py = 0,
                text = "Main Menu",
                callback = function() Logger:debug("Returning to main menu") end,
            })
        else
            -- Update button positions if needed
        end
        self.menuWindow:draw()
    end
end

return EscapeMenu.init()
