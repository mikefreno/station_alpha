local enums = require("utils.enums")
local constants = require("utils.constants")
local helperFunctions = require("utils.helperFunctions")
local EventBus = require("systems.EventBus")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local switch = helperFunctions.switch

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

  switch(type, {
    [ComponentType.SELECTED] = function()
      --TODO: Will need handling checks if multiple are selected - this will work as last selected
      -- Check if selecting a colonist, add to camera if so
      local isColonist = self:getComponent(entityId, ComponentType.COLONIST_TAG)
      if isColonist then
        Camera.selectedEntity = entityId
      end
    end,
    [ComponentType.COLONIST_TAG] = function()
      EventBus:emit("colonist_added")
    end,
  })
end

function EntityManager:removeComponent(entityId, type)
  if not self.components[type] then
    self.components[type] = {}
  end
  self.components[type][entityId] = nil
end

---@param type ComponentType
---@param data any
---@return integer? --entity
function EntityManager:find(type, data)
  local byType = self.components[type]
  if not byType then
    return nil
  end

  for id, comp in pairs(byType) do
    -- direct comparison checks
    if type == ComponentType.SELECTED then
      if comp == data then
        return id
      end
    end
    -- vector checks
    if type == ComponentType.POSITION or type == ComponentType.MAPTILE_TAG then
      if comp.x == data.x and comp.y == data.y then
        return id
      end
    end
  end

  return nil
end

---@param type ComponentType.POSITION | ComponentType.MAPTILE_TAG -- the type to check for
---@param data  Vec2 -- the grid point you want to search from
---@param ignoreTypes ComponentType[]? -- component types which if present on the entity will ignore the entity
---@return integer? --   the entity id of the nearest matching tile, or nil
function EntityManager:findNearest(type, data, ignoreTypes)
  if not data or not data.x or not data.y then
    return nil
  end

  -- Helper to check if an entity should be ignored
  local function shouldIgnore(id)
    if not ignoreTypes then
      return false
    end
    for _, ignoreType in ipairs(ignoreTypes) do
      if self.components[ignoreType] and self.components[ignoreType][id] then
        return true
      end
    end
    return false
  end

  local nearest = nil
  local minDistSq = math.huge

  -- ------------------------------------------------------------------
  -- Helper that checks a single entity id against the data point.
  local function check(id, pos)
    -- Skip if entity should be ignored
    if shouldIgnore(id) then
      return
    end

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
  elseif type == ComponentType.MAPTILE_TAG then
    local positions = self.components[ComponentType.POSITION]
    local tags = self.components[ComponentType.MAPTILE_TAG]
    for id, pos in pairs(positions) do
      if tags[id] then
        check(id, pos)
      end
    end
  end

  return nearest
end

---@overload fun(self: EntityManager, entityId: integer, type: 1): Vec2?  -POSITION
---@overload fun(self: EntityManager, entityId: integer, type: 2): Vec2?  -- VELOCITY
---@overload fun(self: EntityManager, entityId: integer, type: 3): TaskQueue?  -- TASKQUEUE
---@overload fun(self: EntityManager, entityId: integer, type: 4): Texture?  -- TEXTURE
---@overload fun(self: EntityManager, entityId: integer, type: 5): Shape?  -- SHAPE
---@overload fun(self: EntityManager, entityId: integer, type: 6): Topography?  -- TOPOGRAPHY
---@overload fun(self: EntityManager, entityId: integer, type: 7): Vec2?  -- MAPTILE_TAG
---@overload fun(self: EntityManager, entityId: integer, type: 8): number?  -- SPEEDSTAT
---@overload fun(self: EntityManager, entityId: integer, type: 9): Vec2?  -- MOVETO
---@overload fun(self: EntityManager, entityId: integer, type: 10): Schedule?  -- SCHEDULE
---@overload fun(self: EntityManager, entityId: integer, type: 11): boolean?  -- SELECTED
---@overload fun(self: EntityManager, entityId: integer, type: 12): string?  -- NAME
---@overload fun(self: EntityManager, entityId: integer, type: 13): boolean?  -- COLONIST_TAG
---@overload fun(self: EntityManager, entityId: integer, type: 14): number?  -- HEALTH
function EntityManager:getComponent(entityId, type)
  local byType = self.components[type]
  if not byType then
    return nil
  end
  return byType[entityId]
end

--- Get the bounding box for an entity based on its position and shape
---@param entityId integer
---@return {x: number, y: number, width: number, height: number}?
function EntityManager:getEntityBounds(entityId)
  local position = self:getComponent(entityId, ComponentType.POSITION)
  local shape = self:getComponent(entityId, ComponentType.SHAPE)

  if not position or not shape then
    return nil
  end

  -- Convert logical position to pixel coordinates
  local px = position.x * constants.pixelSize - Camera.borderPad * constants.pixelSize
  local py = position.y * constants.pixelSize - Camera.borderPad * constants.pixelSize

  local size = shape.size * constants.pixelSize
  local bounds = {
    x = px,
    y = py,
    width = size,
    height = size,
  }
  return bounds
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
    if ok then
      result[#result + 1] = e
    end
  end
  return result
end

return EntityManager.init()
