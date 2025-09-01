local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local Shapes = enums.Shapes
local EntityManager = require("systems.EntityManager")
local InputSystem = require("systems.Input")
local PositionSystem = require("systems.Position")
local RenderSystem = require("systems.Render")
local Camera = require("components.Camera")
local helperFunctions = require("utils.helperFunctions")
local createLevelMap = helperFunctions.createLevelMap

local overlayStats = require("libs.OverlayStats")
local Logger = require("logger"):init()

function love.load()
	love.window.setTitle("ECS Dot Demo")
	love.window.setMode(800, 600)
	Camera = Camera.new()
	createLevelMap(EntityManager, 150, 150)

	---temporary for demoing purposes---
	local dot = EntityManager:createEntity()
	EntityManager:addComponent(dot, ComponentType.POSITION, { x = 400, y = 300 })
	EntityManager:addComponent(dot, ComponentType.VELOCITY, { x = 0, y = 0 })
	EntityManager:addComponent(dot, ComponentType.TEXTURE, { color = { r = 1, g = 0.5, b = 0 } })
	EntityManager:addComponent(dot, ComponentType.SHAPE, { shape = Shapes.CIRCLE, size = 10 })
	---temporary for demoing purposes---

	overlayStats.load()
end

function love.update(dt)
	--InputSystem:update(EntityManager)
	PositionSystem:update(dt, EntityManager)
	Camera:update(dt)

	overlayStats.update(dt)
end

function love.keypressed(key, scancode, isrepeat)
	overlayStats.handleKeyboard(key)
	Logger:keypressed(key, scancode)
end

function love.wheelmoved(x, y)
	Camera:wheelmoved(x, y)
end

function love.draw()
	Camera:apply()
	RenderSystem:update(EntityManager)
	Camera:unapply()

	Logger:draw()
	overlayStats.draw()
end
