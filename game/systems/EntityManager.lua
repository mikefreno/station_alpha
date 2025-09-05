local enums = require("utils.enums")
local ComponentType = enums.ComponentType

---@class EntityManager
---@field entities   table<number, boolean>
---@field components table<ComponentType, table<number, any>>
local EntityManager = {}
EntityManager.__index = EntityManager

local instance = nil

function EntityManager.init()
    if instance == nil then
        local self = setmetatable({}, EntityManager)
        self.entities = {}
        self.components = {}
        instance = self
    end
    return instance
end

function EntityManager:createEntity()
    local id = #self.entities + 1
    self.entities[id] = true
    return id
end

---@param entityId integer
---@param type ComponentType
---@param data any
function EntityManager:addComponent(entityId, type, data)
    if not self.components[type] then
        self.components[type] = {}
    end
    self.components[type][entityId] = data
end

---@param type ComponentType
---@param data any
---@return integer?
function EntityManager:find(type, data)
    local byType = self.components[type]
    if not byType then
        return nil
    end

    for id, comp in pairs(byType) do
        if type == ComponentType.POSITION then
            if comp.x == data.x and comp.y == data.y then
                return id
            end
        end
    end

    return nil
end

---@param type ComponentType.POSITION | ComponentType.MAPTILETAG
---@param data  Vec2 – the world point you want to search from
---@return integer?  The entity id of the nearest matching tile, or nil
function EntityManager:findNearest(type, data)
    if not data or not data.x or not data.y then
        return nil
    end

    local nearest = nil
    local minDistSq = math.huge

    -- ------------------------------------------------------------------
    -- Helper that checks a single entity id against the data point.
    local function check(id, pos)
        local dx = pos.x - data.x
        local dy = pos.y - data.y
        local distSq = dx * dx + dy * dy
        if distSq < minDistSq then
            minDistSq = distSq
            nearest = id
        end
    end
    -- ------------------------------------------------------------------
    if type == ComponentType.POSITION then
        local positions = self.components[ComponentType.POSITION]
        for id, pos in pairs(positions) do
            check(id, pos)
        end
    elseif type == ComponentType.MAPTILETAG then
        local positions = self.components[ComponentType.POSITION]
        local tags = self.components[ComponentType.MAPTILETAG]

        for id, pos in pairs(positions) do
            if tags[id] then
                check(id, pos)
            end
        end
    end

    return nearest
end

---@param entityId integer
---@param type ComponentType
---@return unknown
function EntityManager:getComponent(entityId, type)
    local byType = self.components[type]
    if not byType then
        return nil
    end
    return byType[entityId]
end

return EntityManager.init()
