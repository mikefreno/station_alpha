local EntityManager = require("game.systems.EntityManager")
local Vec2 = require("game.utils.Vec2")
local constants = require("game.utils.constants")
local ComponentType = require("game.utils.enums").ComponentType

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
        --Slab.BeginWindow("MyFirstWindow", { Title = "Dot Options", X = self.position.x, Y = self.position.y })

        --Slab.Text("Hello World")
        --Slab.Text("This is the Right Click Menu")

        --if Slab.Button("Go To") then ButtonPressed = true end

        if ButtonPressed then
            local currentDotPos = EntityManager:getComponent(EntityManager.dot, ComponentType.POSITION)
            local dotShape = EntityManager:getComponent(EntityManager.dot, ComponentType.SHAPE)

            local worldX = (self.position.x / Camera.zoom) + (Camera.position.x * constants.pixelSize)
            local worldY = (self.position.y / Camera.zoom) + (Camera.position.y * constants.pixelSize)
            local clickGrid = MapManager:worldToGrid(Vec2.new(worldX, worldY))
            local path = Pathfinder:findPath(currentDotPos:add(dotShape.size / 2, dotShape.size / 2), clickGrid)
            if path ~= nil then TaskManager:newPath(EntityManager.dot, path) end
            self.showing = false
            ButtonPressed = false
        end

        --Slab.EndWindow()
    end
end

function RightClickMenu:hide()
    self.showing = false
    self.position = nil
end

return RightClickMenu
