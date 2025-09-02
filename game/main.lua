local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TaskType = enums.TaskType
local EntityManager = require("systems.EntityManager")
local InputSystem = require("systems.Input")
local PositionSystem = require("systems.Position")
local RenderSystem = require("systems.Render")
local Camera = require("components.Camera")
local helperFunctions = require("utils.helperFunctions")
local createLevelMap = helperFunctions.createLevelMap
local Vec2 = require("utils.Vec2")
local pathfinder = require("systems.PathFinder")
local TILE_SIZE = require("utils.constants").TILE_SIZE

local overlayStats = require("libs.OverlayStats")
Logger = require("logger"):init()
local TaskQueue = require("systems.TaskQueue")

function love.load()
	love.window.setTitle("ECS Dot Demo")
	love.window.setMode(800, 600)
	Camera = Camera.new()
	createLevelMap(EntityManager, 150, 150)

	---temporary for demoing purposes---
	Dot = EntityManager:createEntity()
	EntityManager:addComponent(Dot, ComponentType.POSITION, Vec2.new(400, 300))
	EntityManager:addComponent(Dot, ComponentType.VELOCITY, Vec2.new(0, 0))
	EntityManager:addComponent(Dot, ComponentType.TEXTURE, { color = { r = 1, g = 0.5, b = 0 } })
	EntityManager:addComponent(Dot, ComponentType.SHAPE, { shape = ShapeType.CIRCLE, size = 10 })
	EntityManager:addComponent(Dot, ComponentType.TASKQUEUE, TaskQueue.new())
	---temporary for demoing purposes---

	overlayStats.load()
end

function love.update(dt)
	--InputSystem:update(EntityManager)
	PositionSystem:update(dt, EntityManager)
	Camera:update(dt)

	for e, _ in pairs(EntityManager.entities) do
		local tq = EntityManager:getComponent(e, ComponentType.TASKQUEUE)
		if tq and #tq.queue > 0 then
			tq:update(dt, e, EntityManager)
		end
	end

	overlayStats.update(dt)
end

function love.keypressed(key, scancode, isrepeat)
	overlayStats.handleKeyboard(key)
	Logger:keypressed(key, scancode)
end

function love.mousepressed(x, y, button, istouch)
	if button == 1 then -- left‑click
		local function closestMultiple(n, k)
			return math.floor(n / k) * k
		end

		local worldX = (x / Camera.zoom) + Camera.x
		local worldY = (y / Camera.zoom) + Camera.y

		local clickVec = Vec2.new(closestMultiple(worldX, TILE_SIZE), closestMultiple(worldY, TILE_SIZE))

		local path = pathfinder:findPath(EntityManager, Dot, clickVec)
		Logger:debug(#path)

		if path and #path > 0 then
			local taskQueue = EntityManager:getComponent(Dot, ComponentType.TASKQUEUE)
			if taskQueue then
				for _, wp in ipairs(path) do
					Logger:debug("adding: " .. wp)
					taskQueue:push({
						type = TaskType.MOVETO,
						target = { x = wp.x, y = wp.y }, -- a plain Vec2 table
					})
				end
			end
		end
	end
end

function love.wheelmoved(x, y)
	if love.keyboard.isDown("lctrl") then
		Logger:wheelmoved(x, y)
	else
		Camera:wheelmoved(x, y)
	end
end

function love.draw()
	Camera:apply()
	RenderSystem:update(EntityManager)
	Camera:unapply()

	Logger:draw()
	overlayStats.draw()
end
