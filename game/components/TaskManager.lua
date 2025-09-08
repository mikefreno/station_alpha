local taskQueue = require("components.TaskQueue")
---this class servers to choose what the next task should be for its attached
---entity
---@class TaskManager
---@field entity integer
---@field taskQueue TaskQueue
local TaskManager = {}
TaskManager.__index = TaskManager

---comment
---@param entity integer
---@return TaskManager
function TaskManager:new(entity)
    local self = setmetatable({}, TaskManager)
    self.entity = entity
    self.taskQueue = taskQueue.new(entity)
    return self
end
