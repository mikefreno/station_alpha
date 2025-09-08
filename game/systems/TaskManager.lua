local enum = require("utils.enums")
local ComponentType = enum.ComponentType
local TaskType = enum.TaskType
local Vec2 = require("utils.Vec2")
---this class servers to choose what the next task should be for its attached
---entity
---@class TaskManager
---@field entityManager EntityManager
---@field mapManager MapManager
local TaskManager = {}
TaskManager.__index = TaskManager

local instance = nil

---comment
---@param entityManager EntityManager
---@param mapManager MapManager
---@return TaskManager
function TaskManager.init(entityManager, mapManager)
    if instance == nil then
        local self = setmetatable({}, TaskManager)
        self.entityManager = entityManager
        self.mapManager = mapManager
        instance = self
        return self
    end
    return instance
end

---@param dt number
---@param mapManager MapManager
function TaskManager:update(dt)
    for e, _ in pairs(self.entityManager.entities) do
        local tq = self.entityManager:getComponent(e, ComponentType.TASKQUEUE)
        if tq then
            tq:update(dt, self.entityManager, self.mapManager)
        end
    end
end

---@param entity integer
---@param path table<integer, {type:TaskType, data:Vec2}>
function TaskManager:newPath(entity, path)
    if path and #path > 0 then
        local taskQueue = self.entityManager:getComponent(entity, ComponentType.TASKQUEUE)
        if taskQueue then
            taskQueue:reset()
            for _, wp in ipairs(path) do
                taskQueue:push(wp)
            end
        end
    end
end

return TaskManager
