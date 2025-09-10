local Vec2 = require("game.utils.Vec2")
local Slab = require("libs.Slab")
local EntityManager = require("game.systems.EntityManager")
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
        Slab.BeginWindow("MyFirstWindow", { Title = "Dot Options", X = self.position.x, Y = self.position.y })

        Slab.Text("Hello World")
        Slab.Text("This is the Right Click Menu")

        if Slab.Button("Go To") then ButtonPressed = true end

        if ButtonPressed then
            local currentDotPos = EntityManager:getComponent(EntityManager.dot, ComponentType.POSITION)
            local dotShape = EntityManager:getComponent(EntityManager.dot, ComponentType.SHAPE)

            local mapManager = EntityManager:getComponent(EntityManager.god, ComponentType.MAPMANAGER)
            local pathfinder = EntityManager:getComponent(EntityManager.god, ComponentType.PATHFINDER)
            local taskManager = EntityManager:getComponent(EntityManager.god, ComponentType.TASKMANAGER)

            local clickGrid = mapManager:worldToGrid(Vec2.new(self.position.x, self.position.y))
            local path =
                pathfinder:findPath(currentDotPos:add(dotShape.size / 2, dotShape.size / 2), clickGrid, mapManager)
            Logger:debug(#path)
            if path == nil then return end
            taskManager:newPath(EntityManager.dot, path)
        end

        Slab.EndWindow()
    end
end

function RightClickMenu:hide()
    self.showing = false
    self.position = nil
end

return RightClickMenu
