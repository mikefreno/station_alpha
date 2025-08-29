local ComponentType = require("utils.enums").ComponentType

local MovementSystem = {}
MovementSystem.__index = MovementSystem

function MovementSystem.new()
    local self = setmetatable({}, MovementSystem)
    return self
end

function MovementSystem:update(dt, entityManager)
    for _, e in ipairs(self:query(entityManager, ComponentType.POSITION, ComponentType.VELOCITY)) do
        local p = entityManager:getComponent(e, ComponentType.POSITION)
        local v = entityManager:getComponent(e, ComponentType.VELOCITY)
        p.x = p.x + v.x * dt
        p.y = p.y + v.y * dt
    end
end

function MovementSystem:query(entityManager, ...)
    local required = { ... }
    local result = {}
    for e, _ in pairs(entityManager.entities) do
        local ok = true
        for _, t in ipairs(required) do
            if not entityManager.comps[t] or not entityManager.comps[t][e] then ok = false break end
        end
        if ok then result[#result + 1] = e end
    end
    return result
end

return MovementSystem.new()
