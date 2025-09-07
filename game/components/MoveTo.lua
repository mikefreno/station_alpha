local Vec2 = require("utils.Vec2")
local enums = require("utils.enums")
local ComponentType = enums.ComponentType

---@class MoveTo
---@field target Vec2
local MoveTo = {}
MoveTo.__index = MoveTo

---@param target Vec2
---@return MoveTo
function MoveTo.new(target)
    local self = setmetatable({}, MoveTo)
    self.target = target
    return self
end

---comment
---@param id integer
---@param entityManager EntityManager
---@param cleanupFunc function
function MoveTo:update(id, entityManager, cleanupFunc)
    local pos = entityManager:getComponent(id, ComponentType.POSITION)
    local distToTarget = self.target:sub(pos):length()
    if distToTarget <= 1e-2 then
        cleanupFunc()
        return true
    end
    return false
end

return MoveTo
