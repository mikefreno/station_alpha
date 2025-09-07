local enums = require("utils.enums")
local MoveTo = require("components.MoveTo")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

---@class TaskQueue
---@field ownerId integer
---@field queue table<integer, {type: TaskType, data: any}>
---@field currentTask MoveTo?
local TaskQueue = {}

---@param ownerId integer
function TaskQueue.new(ownerId)
    local self = setmetatable({}, { __index = TaskQueue })
    self.ownerId = ownerId
    self.queue = {}
    self.currentTask = nil
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

---@param dt number
---@param entityMgr EntityManager
function TaskQueue:update(dt, entityMgr)
    if self.currentTask and self.currentTask.duration <= self.currentTask.elapsed then
        self.currentTask = nil
    end
    if self.currentTask then
        self.currentTask:update(dt, entityMgr)
    else
        if #self.queue == 0 then
            return
        end

        local nextTask = self:pop()

        if nextTask.type == TaskType.MOVETO then
            local currentPos = entityMgr:getComponent(self.ownerId, ComponentType.POSITION)
            local nextPos = nextTask.data
            local diff = nextPos:sub(nextPos)
            local speedStat = entityMgr:getComponent(self.ownerId, ComponentType.SPEEDSTAT)
            local duration = diff:length() / speedStat
            local moveto = MoveTo.new(currentPos, nextPos, duration, self.ownerId, diff)
            self.currentTask = moveto
        end
    end
end

return TaskQueue
