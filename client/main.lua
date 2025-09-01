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
local Vec2 = require("utils.Vec2")
local pathfinder = require("systems.PathFinder")

local overlayStats = require("libs.OverlayStats")
local Logger = require("logger"):init()
local taskQueue = require("systems.TaskQueue")

function love.load()
	love.window.setTitle("ECS Dot Demo")
	love.window.setMode(800, 600)
	Camera = Camera.new()
	createLevelMap(EntityManager, 150, 150)

	---temporary for demoing purposes---
	Dot = EntityManager:createEntity()
	EntityManager:addComponent(Dot, ComponentType.POSITION, { x = 400, y = 300 })
	EntityManager:addComponent(Dot, ComponentType.VELOCITY, { x = 0, y = 0 })
	EntityManager:addComponent(Dot, ComponentType.TEXTURE, { color = { r = 1, g = 0.5, b = 0 } })
	EntityManager:addComponent(Dot, ComponentType.SHAPE, { shape = Shapes.CIRCLE, size = 10 })
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

function love.mousepressed(x, y, button, istouch)
	if button == 1 then -- left‑click
		-- 1. turn screen → world (camera zoom / translate)
		local worldX = (x / Camera.zoom) + Camera.x
		local worldY = (y / Camera.zoom) + Camera.y

		-- 2. store the destination as a temporary "entity"
		--    you can just keep the Vec2 if you don’t need an Entity id
		local clickVec = Vec2.new(worldX, worldY)

		-- 3. compute a path
		local path = pathfinder:findPath(EntityManager, Dot, clickVec)

		-- 4. push the path to the queue
		if #path > 0 then
			taskQueue:push({ entity = Dot, path = path })
		end
	end
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
