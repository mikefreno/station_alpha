local compareTables = require("utils.helperFunctions").compareTables
local enums = require("utils.enums")
local ComponentType = enums.ComponentType

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

---@param type ComponentType
---@param data any
function EntityManager:find(type, data)
	local compTable = self.components[type]

	if not compTable then
		return nil -- no entity has this component type
	end

	for id, comp in pairs(compTable) do
		if ComponentType.POSITION then
			if comp.x == data.x and comp.y == data.y then
				return id
			end
		end
	end

	return nil -- nothing matched
end

---comment
---@param entityId integer
---@param type ComponentType
---@return unknown
function EntityManager:getComponent(entityId, type)
	return self.components[type] and self.components[type][entityId]
end

return EntityManager.new()
