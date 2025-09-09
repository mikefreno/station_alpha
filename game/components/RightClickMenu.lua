local Vec2 = require("utils.Vec2")
local Slab = require("libs.Slab")

---@class RightClickMenu
---@field position Vec2?
---@field showing boolean
---@field contents {}
local RightClickMenu = {}
RightClickMenu.__index = RightClickMenu

function RightClickMenu.new()
    local self = setmetatable({}, RightClickMenu)
    self.position = nil
    self.showing = false
end

function RightClickMenu:render()
    if self.showing then
        Slab.BeginWindow(
            "MyFirstWindow",
            { Title = "Dot Options", Position = { x = self.position.x, y = self.position.y } }
        )
        Slab.Text("Hello World")
        Slab.EndWindow()
    end
end

function RightClickMenu:hide()
    self.showing = false
    self.position = nil
end

return RightClickMenu
