local ComponentType = require("utils.enums").ComponentType
local EntityManager = require("systems.EntityManager")
local InputSystem = require("systems.Input")
local MovementSystem = require("systems.Movement")
local RenderSystem = require("systems.Render")

function love.load()
    love.window.setTitle("ECS Dot Demo")
    love.window.setMode(800, 600)

    local dot = EntityManager:createEntity()
    EntityManager:addComponent(dot, ComponentType.POSITION, { x = 400, y = 300 })
    EntityManager:addComponent(dot, ComponentType.VELOCITY, { x = 0, y = 0 })
end

function love.update(dt)
    InputSystem:update(EntityManager)
    MovementSystem:update(dt, EntityManager)
end

function love.draw()
    RenderSystem:update(EntityManager)
end
