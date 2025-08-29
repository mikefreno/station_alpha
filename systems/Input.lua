local ComponentType = require("utils.enums").ComponentType

local InputSystem = {}
InputSystem.__index = InputSystem

function InputSystem.new()
    local self = setmetatable({}, InputSystem)
    return self
end

function InputSystem:update(entityManager)
    for _, e in ipairs(self:query(entityManager, ComponentType.VELOCITY)) do
        local v = entityManager:getComponent(e, ComponentType.VELOCITY)
        v.x, v.y = 0, 0
        if love.keyboard.isDown("left") then v.x = v.x - 200 end
        if love.keyboard.isDown("right") then v.x = v.x + 200 end
        if love.keyboard.isDown("up") then v.y = v.y - 200 end
        if love.keyboard.isDown("down") then v.y = v.y + 200 end
    end
end

function InputSystem:query(entityManager, ...)
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

return InputSystem.new()
