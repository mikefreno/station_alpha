---@class EntityManager
---@field entities {}
---@field components {}
local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.new()
    local self = setmetatable({}, EntityManager)
    self.entities = {}
    self.components = {}
    return self
end

function EntityManager:createEntity()
    local id = #self.entities + 1
    self.entities[id] = true
    return id
end

---comment
---@param entityId integer 
---@param type ComponentType
---@param data any
function EntityManager:addComponent(entityId, type, data)
    if not self.components[type] then
        self.components[type] = {}
    end
    self.components[type][entityId] = data
end

---comment
---@param entityId integer
---@param type ComponentType
---@return unknown
function EntityManager:getComponent(entityId, type)
    return self.components[type] and self.components[type][entityId]
end

return EntityManager.new()
