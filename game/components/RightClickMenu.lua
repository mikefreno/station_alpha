local Vec2 = require("utils.Vec2")
local Slab = require("libs.Slab")

---@class RightClickMenu
---@field position Vec2?
---@field showing boolean
---@field contents {}
---@field hovered boolean
local RightClickMenu = {}
RightClickMenu.__index = RightClickMenu

function RightClickMenu.new()
    local self = setmetatable({}, RightClickMenu)
    self.position = nil
    self.showing = false
    self.contents = {}
    self.hovered = false
    return self
end

function RightClickMenu:render()
    if self.showing then
        Logger:debug("called")
        Slab.BeginWindow("MyFirstWindow", { Title = "Dot Options", X = self.position.x, Y = self.position.y })

        Slab.Text("Hello World")
        Slab.Text("This is the Right Click Menu")

        if Slab.Button("My Button") then ButtonPressed = true end

        if ButtonPressed then Slab.Text("Button was pressed!") end

        Slab.EndWindow()
    end
end

function RightClickMenu:hide()
    self.showing = false
    self.position = nil
end

return RightClickMenu
