local enums = require("game.utils.enums")
local constants = require("game.utils.constants")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType

---@class EntityManager
---@field entities   table<number, boolean>
---@field components table<ComponentType, table<number, any>>
---@field god integer
---@field dot integer
local EntityManager = {}
EntityManager.__index = EntityManager

local instance = nil

function EntityManager.init()
    if instance == nil then
        local self = setmetatable({}, EntityManager)
        self.entities = {}
        self.components = {}
        instance = self
        self.dot = self:createEntity()
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
    if not self.components[type] then self.components[type] = {} end
    self.components[type][entityId] = data
end

function EntityManager:removeComponent(entityId, type)
    if not self.components[type] then self.components[type] = {} end
    self.components[type][entityId] = nil
end

---@param type ComponentType
---@param data any
---@return integer? --entity
function EntityManager:find(type, data)
    local byType = self.components[type]
    if not byType then return nil end

    for id, comp in pairs(byType) do
        if type == ComponentType.POSITION or type == ComponentType.MAPTILETAG then
            if comp.x == data.x and comp.y == data.y then return id end
        end
    end

    return nil
end

---@param type ComponentType.POSITION | ComponentType.MAPTILETAG
---@param data  Vec2 – the world point you want to search from
---@return integer?  The entity id of the nearest matching tile, or nil
function EntityManager:findNearest(type, data)
    if not data or not data.x or not data.y then return nil end

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
            if tags[id] then check(id, pos) end
        end
    end

    return nearest
end

---@param entityId integer
---@param type ComponentType
---@return unknown
function EntityManager:getComponent(entityId, type)
    local byType = self.components[type]
    if not byType then return nil end
    return byType[entityId]
end

--- Get the bounding box for an entity based on its position and shape
---@param entityId integer
---@return {x: number, y: number, width: number, height: number}?
function EntityManager:getEntityBounds(entityId)
    local position = self:getComponent(entityId, ComponentType.POSITION)
    local shape = self:getComponent(entityId, ComponentType.SHAPE)

    if not position or not shape then return nil end

    -- Convert logical position to pixel coordinates
    local px = position.x * constants.pixelSize
    local py = position.y * constants.pixelSize

    if shape.shape == ShapeType.CIRCLE then
        -- For a circle, the bounding box is a square with side length = diameter
        local size = shape.size * constants.pixelSize
        return {
            x = px - size / 2,
            y = py - size / 2,
            width = size,
            height = size,
        }
    elseif shape.shape == ShapeType.SQUARE then
        -- For a square, use the size directly
        local size = shape.size * constants.pixelSize
        return {
            x = px,
            y = py,
            width = size,
            height = size,
        }
    else
        -- Default to a simple rectangle based on position
        return {
            x = px,
            y = py,
            width = constants.pixelSize,
            height = constants.pixelSize,
        }
    end
end

---@param ... ComponentType
---@return integer[] entities
function EntityManager:query(...)
    local required = { ... }
    local result = {}
    for e, _ in pairs(self.entities) do
        local ok = true
        for _, t in ipairs(required) do
            if not self.components[t] or not self.components[t][e] then
                ok = false
                break
            end
        end
        if ok then result[#result + 1] = e end
    end
    return result
end

return EntityManager.init()
