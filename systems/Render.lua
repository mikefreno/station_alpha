local ComponentType = require("utils.enums").ComponentType

local RenderSystem = {}
RenderSystem.__index = RenderSystem

function RenderSystem.new()
    local self = setmetatable({}, RenderSystem)
    return self
end

function RenderSystem:update(entityManager)
    love.graphics.clear(0.1, 0.1, 0.1)
    for _, e in ipairs(self:query(entityManager, ComponentType.POSITION)) do
        local p = entityManager:getComponent(e, ComponentType.POSITION)
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle("fill", p.x, p.y, 10)
    end
end

function RenderSystem:query(entityManager, ...)
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

return RenderSystem.new()
