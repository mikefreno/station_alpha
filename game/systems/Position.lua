local ComponentType = require("utils.enums").ComponentType

local PositionSystem = {}
PositionSystem.__index = PositionSystem

function PositionSystem.new()
    local self = setmetatable({}, PositionSystem)
    return self
end

---comment
---@param dt number
---@param entityManager EntityManager
function PositionSystem:update(dt, entityManager)
    for _, e in ipairs(self:query(entityManager, ComponentType.POSITION, ComponentType.VELOCITY)) do
        local p = entityManager:getComponent(e, ComponentType.POSITION)
        local v = entityManager:getComponent(e, ComponentType.VELOCITY)
        p.x = p.x + v.x * dt
        p.y = p.y + v.y * dt
    end
end

---@param entityManager EntityManager
function PositionSystem:query(entityManager, ...)
    local required = { ... }
    local result = {}
    for e, _ in pairs(entityManager.entities) do
        local ok = true
        for _, t in ipairs(required) do
            if not entityManager.components[t] or not entityManager.components[t][e] then
                ok = false
                break
            end
        end
        if ok then
            result[#result + 1] = e
        end
    end
    return result
end

---@param entityManager EntityManager
---@param entityToMove integer
---@param targetEntity integer
function PositionSystem:createTask(entityManager, entityToMove, targetEntity)
    local origin = entityManager:getComponent(entityToMove, ComponentType.POSITION)
    local target = entityManager:getComponent(targetEntity, ComponentType.POSITION)
end

return PositionSystem.new()
