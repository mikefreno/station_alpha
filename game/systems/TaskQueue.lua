local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType
local TILE_SIZE = require("utils.constants")

---@class TaskQueue
---@field ownerId integer
---@field queue table<integer, {type: TaskType, data: any}>
local TaskQueue = {}

---@param ownerId integer
function TaskQueue.new(ownerId)
	local self = setmetatable({}, { __index = TaskQueue })
	self.ownerId = ownerId
	self.queue = {}
	return self
end

---@overload fun(task: {type: TaskType.WORK, data: any})
---@param task {type: TaskType.MOVETO, data: Vec2}
function TaskQueue:push(task)
	table.insert(self.queue, task)
end

function TaskQueue:pop()
	return table.remove(self.queue, 1)
end

local timer = 1.0
---@param dt number
---@param entityMgr EntityManager
function TaskQueue:update(dt, entityMgr)
	timer = timer - dt
	if timer > 0 then
		return
	end
	Logger:debug(#self.queue)
	local currentTask = self:pop()

	if not currentTask then
		local v = entityMgr:getComponent(self.ownerId, ComponentType.VELOCITY)
		if v then
			v.x, v.y = 0, 0
		end
		return
	end

	local currentPos = entityMgr:getComponent(self.ownerId, ComponentType.POSITION)
	Logger:debug("current position: " .. currentPos.x .. "," .. currentPos.y)
	Logger:debug("new position: " .. currentTask.data.x .. "," .. currentTask.data.y)

	if currentTask.type == TaskType.MOVETO then
		entityMgr:addComponent(self.ownerId, ComponentType.POSITION, currentTask.data)
	end

	timer = 1.0
end

return TaskQueue
