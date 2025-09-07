local enums = require("utils.enums")
local MoveTo = require("components.MoveTo")
local Vec2 = require("utils.Vec2")
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

function TaskQueue:push(task)
    table.insert(self.queue, task)
end

function TaskQueue:pop()
    return table.remove(self.queue, 1)
end

---@param dt number
---@param entityManager EntityManager
---@param mapManager MapManager
function TaskQueue:update(dt, entityManager, mapManager)
    -- If there's an active MoveTo, advance it
    if self.currentTask then
        local finished = self.currentTask:update(dt, entityManager)
        if finished then
            self.currentTask = nil
        end
        return
    end

    -- If no current task, start the next one
    if #self.queue == 0 then
        return
    end

    local nextTask = self:pop()
    if nextTask.type == TaskType.MOVETO then
        local currentPos = entityManager:getComponent(self.ownerId, ComponentType.POSITION)
        local nextPos = nextTask.data
        -- ensure Vec2 instances
        if not currentPos or not nextPos then
            return
        end

        local diff = nextPos:sub(currentPos) -- vec from current -> next
        local distance = diff:length()

        -- read speed stat (tiles per second). If stored as component object, extract numeric.
        local speed = entityManager:getComponent(self.ownerId, ComponentType.SPEEDSTAT)

        local duration = 0.0001
        if distance > 0 then
            duration = distance / math.max(0.0001, speed)
            if mapManager then
                local tile = mapManager:getNode(nextPos.x, nextPos.y)
                if tile and tile.speedMultiplier and tile.speedMultiplier > 0 then
                    duration = duration / tile.speedMultiplier
                end
            end
        end

        self.currentTask = MoveTo.new(currentPos, nextPos, duration, self.ownerId, diff)
    elseif nextTask.type == TaskType.WORK then
        -- handle other task types
    end
end

return TaskQueue
