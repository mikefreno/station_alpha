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

return TaskQueue
