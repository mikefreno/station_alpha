local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.new()
    local self = setmetatable({}, EntityManager)
    self.entities = {}
    self.comps = {}
    return self
end

function EntityManager:createEntity()
    local id = #self.entities + 1
    self.entities[id] = true
    return id
end

function EntityManager:addComponent(e, type, data)
    if not self.comps[type] then
        self.comps[type] = {}
    end
    self.comps[type][e] = data
end

function EntityManager:getComponent(e, type)
    return self.comps[type] and self.comps[type][e]
end

return EntityManager.new()
