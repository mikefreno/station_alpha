local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local TILE_SIZE = require("utils.constants")

---@class TaskQueue
---@field queue table
local TaskQueue = {}

function TaskQueue.new()
	local self = setmetatable({}, { __index = TaskQueue })
	self.queue = {}
	return self
end

function TaskQueue:push(task)
	table.insert(self.queue, task)
end

function TaskQueue:pop()
	return table.remove(self.queue, 1)
end

local timer = 1.0
function TaskQueue:update(dt, entity, entityMgr)
	timer = timer - dt
	if timer > 0 then
		return
	end
	Logger:debug(#self.queue)
	local curTask = self.queue[1]
	if not curTask then
		-- nothing to do – stop the entity
		local v = entityMgr:getComponent(entity, ComponentType.VELOCITY)
		if v then
			v.x, v.y = 0, 0
		end
		return
	end

	local pos = entityMgr:getComponent(entity, ComponentType.POSITION)
	local vel = entityMgr:getComponent(entity, ComponentType.VELOCITY)

	if not pos or not vel then
		return
	end

	local target = curTask.target
	local dx = target.x - pos.x
	local dy = target.y - pos.y
	local dist = math.sqrt(dx * dx + dy * dy)

	-- If we are already at the target (within 1 pixel) pop the task
	if dist < 1 then
		self:pop()
		vel.x, vel.y = 0, 0
		return
	end

	local speed = TILE_SIZE
	vel.x = dx / dist * speed
	vel.y = dy / dist * speed
	timer = 1.0
end

return TaskQueue
