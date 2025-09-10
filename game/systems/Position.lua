local ComponentType = require("game.utils.enums").ComponentType
local Vec2 = require("game.utils.Vec2")
local constants = require("game.utils.constants")

local PositionSystem = {}
PositionSystem.__index = PositionSystem

function PositionSystem.new()
    local self = setmetatable({}, PositionSystem)
    return self
end

---@param dt number
function PositionSystem:update(dt)
    for _, e in ipairs(self:query(ComponentType.POSITION, ComponentType.VELOCITY, ComponentType.MOVETO)) do
        local p = EntityManager:getComponent(e, ComponentType.POSITION)
        local v = EntityManager:getComponent(e, ComponentType.VELOCITY)
        local moveto = EntityManager:getComponent(e, ComponentType.MOVETO)

        if moveto then
            local dirToTarget = moveto.target:sub(p)
            local remainingDist = dirToTarget:length()

            if remainingDist < 1e-6 then
                p.x, p.y = moveto.target.x, moveto.target.y
                EntityManager:removeComponent(e, ComponentType.MOVETO)
                v.x, v.y = 0, 0 -- stop moving
                goto next_entity
            end

            local speedStat = EntityManager:getComponent(e, ComponentType.SPEEDSTAT)
            local intx = math.floor(p.x + 0.5) -- dot (and future entities will render at center, need to align with visuals)
            local inty = math.floor(p.y + 0.5)
            local currentTileEntity = EntityManager:find(ComponentType.MAPTILETAG, Vec2.new(intx, inty))
            if currentTileEntity == nil then
                Logger:error("could not place entity: " .. e .. "(" .. intx .. "," .. inty)
                return
            end
            local topography = EntityManager:getComponent(currentTileEntity, ComponentType.TOPOGRAPHY)
            local newVel = moveto.target:sub(p):normalize():mul(topography.speedMultiplier * speedStat)
            local step = newVel:mul(dt)

            if step:length() >= remainingDist then
                p.x, p.y = moveto.target.x, moveto.target.y
                EntityManager:removeComponent(e, ComponentType.MOVETO)
                v.x, v.y = 0, 0
            else
                -- Normal movement
                --
                p.x = p.x + step.x
                p.y = p.y + step.y
            end
            goto next_entity
        end

        p.x = p.x + v.x * dt
        p.y = p.y + v.y * dt

        ::next_entity::
    end
end

function PositionSystem:query(...)
    local required = { ... }
    local result = {}
    for e, _ in pairs(EntityManager.entities) do
        local ok = true
        for _, t in ipairs(required) do
            if not EntityManager.components[t] or not EntityManager.components[t][e] then
                ok = false
                break
            end
        end
        if ok then result[#result + 1] = e end
    end
    return result
end

---@param entityToMove integer
---@param targetEntity integer
function PositionSystem:createTask(entityToMove, targetEntity)
    local origin = EntityManager:getComponent(entityToMove, ComponentType.POSITION)
    local target = EntityManager:getComponent(targetEntity, ComponentType.POSITION)
end

return PositionSystem.new()
