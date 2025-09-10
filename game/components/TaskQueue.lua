local enums = require("game.utils.enums")
local MoveTo = require("game.components.MoveTo")
local Vec2 = require("game.utils.Vec2")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

---@class TaskQueue
---@field ownerId integer
---@field queue table<integer, {type: TaskType, data: any}>
---@field currentTask MoveTo?
local TaskQueue = {}

---@param ownerId integer
---@param mapManager? MapManager   -- optional: pass mapManager for terrain speed lookups
function TaskQueue.new(ownerId, mapManager)
    local self = setmetatable({}, { __index = TaskQueue })
    self.ownerId = ownerId
    self.queue = {}
    self.currentTask = nil
    self.mapManager = mapManager -- store reference if available
    return self
end

function TaskQueue:reset()
    self.queue = {}
    self.currentTask = nil
end

function TaskQueue:push(task) table.insert(self.queue, task) end

function TaskQueue:pop() return table.remove(self.queue, 1) end

---@param dt number
---@param entityManager EntityManager
function TaskQueue:update(dt, entityManager)
    local function cleanup()
        --align
        local p = entityManager:getComponent(self.ownerId, ComponentType.POSITION)
        local v = entityManager:getComponent(self.ownerId, ComponentType.VELOCITY)
        v = Vec2.new(0, 0)
        p = self.currentTask.target
        --clear
        self.currentTask = nil
    end
    if self.currentTask then
        local calledCleanup = self.currentTask:update(self.ownerId, entityManager, cleanup)
        if not calledCleanup then return end
    end
    -- If no current task, start the next one
    if #self.queue == 0 then return end

    local nextTask = self:pop()
    if nextTask.type == TaskType.MOVETO then
        self.currentTask = MoveTo.new(nextTask.data)
        entityManager:addComponent(self.ownerId, ComponentType.MOVETO, self.currentTask)
    elseif nextTask.type == TaskType.WORK then
        -- handle other task types
    end
end

return TaskQueue
