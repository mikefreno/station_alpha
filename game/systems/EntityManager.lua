local enums = require("utils.enums")
local ComponentType = enums.ComponentType

---@class EntityManager
---@field entities   table<number, boolean>
---@field components table<ComponentType, table<number, any>>
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

---@param type ComponentType.POSITION
---@param data Vec2
---@return integer?
function EntityManager:findNearest(type, data)
  local xdif = math.huge
  local ydif = math.huge
  local nearest = -1
  local byType = self.components[type]
  for id, component in pairs(byType) do
  end
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

return EntityManager.new()
