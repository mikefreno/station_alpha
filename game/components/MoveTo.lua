local Vec2 = require("utils.Vec2")
local enums = require("utils.enums")
local ComponentType = enums.ComponentType

---@class MoveTo
---@field from Vec2
---@field to Vec2
---@field distance Vec2
---@field duration number
---@field elapsed number
---@field owner integer
local MoveTo = {}
MoveTo.__index = MoveTo

---@param from Vec2
---@param to Vec2
---@param duration number
---@param ownerId integer
---@param distance Vec2?   -- optional, will compute if nil
---@return MoveTo
function MoveTo.new(from, to, duration, ownerId, distance)
    local self = setmetatable({}, MoveTo)
    self.from = Vec2.new(from.x, from.y)
    self.to = Vec2.new(to.x, to.y)
    self.distance = distance or self.to:sub(self.from) -- Vec2
    self.duration = math.max(0.0001, duration or 0.25) -- avoid zero duration
    self.elapsed = 0
    self.owner = ownerId
    return self
end

--- @param dt number
--- @param entityManager EntityManager
--- @return boolean finished
function MoveTo:update(dt, entityManager)
    self.elapsed = self.elapsed + dt
    local t = math.min(1, self.elapsed / self.duration)

    local interp = t

    local newPos = self.from:lerp(self.to, interp)
    local ownerPos = entityManager:getComponent(self.owner, ComponentType.POSITION)
    if ownerPos then
        ownerPos.x = newPos.x
        ownerPos.y = newPos.y
    else
        -- if no POSITION component, add one (unlikely)
        entityManager:addComponent(self.owner, ComponentType.POSITION, Vec2.new(newPos.x, newPos.y))
    end

    return t >= 1
end

return MoveTo
