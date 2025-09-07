local ComponentType = require("utils.enums").ComponentType
local Vec2 = require("utils.Vec2")
local constants = require("utils.constants")

local PositionSystem = {}
PositionSystem.__index = PositionSystem

function PositionSystem.new()
    local self = setmetatable({}, PositionSystem)
    return self
end
local movetoTarget
local top = { speedMultiplier = 0 }

---@param dt number
---@param entityManager EntityManager
function PositionSystem:update(dt, entityManager)
    for _, e in ipairs(self:query(entityManager, ComponentType.POSITION, ComponentType.VELOCITY)) do
        local p = entityManager:getComponent(e, ComponentType.POSITION)
        local v = entityManager:getComponent(e, ComponentType.VELOCITY)
        local moveto = entityManager:getComponent(e, ComponentType.MOVETO)
        local speedStat = entityManager:getComponent(e, ComponentType.SPEEDSTAT)
        if moveto then
            local intx = math.floor(p.x + 0.5) -- dot (and future entities will render at center, need to align with visuals)
            local inty = math.floor(p.y + 0.5)
            local currentTileEntity = entityManager:find(ComponentType.MAPTILETAG, Vec2.new(intx, inty))
            if currentTileEntity == nil then
                Logger:error("could not place entity: " .. e .. "(" .. intx .. "," .. inty)
                return
            end
            local topography = entityManager:getComponent(currentTileEntity, ComponentType.TOPOGRAPHY)

            local newVel = moveto.target:sub(p):normalize():mul(topography.speedMultiplier * speedStat)
            if moveto ~= movetoTarget then
                Logger:debug("target" .. moveto.target.x .. "," .. moveto.target.y)
                Logger:debug("current" .. p.x .. "," .. p.y)
                Logger:debug("speedstat" .. speedStat)
                movetoTarget = moveto
            end
            if topography.speedMultiplier ~= top.speedMultiplier then
                Logger:debug("speed mult" .. topography.speedMultiplier)
                top.speedMultiplier = topography.speedMultiplier
            end
            v = newVel
        end
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
