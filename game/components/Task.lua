local enums = require("game.utils.enums")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType
---@class Task
---@field type TaskType
---@field target integer|Vec2 -- Entity ID or position(Vec2)
---@field performer integer -- Entity ID
local Task = {}
Task.__index = Task

---@param type TaskType
---@param target integer | Vec2
function Task.new(type, target)
  --TODO: may want to check for target existence, for sure will want to before we perform
  local self = setmetatable({}, Task)
  self.type = type
  self.target = target
  return self
end

---@param colonistEntityId integer
function Task:assignColonist(colonistEntityId)
  self.performer = colonistEntityId
end

function Task:perform()
  local targetPos
  if type(self.target) == "integer" then
    --- self.target will only ever be an integer here.
    ---@diagnostic disable-next-line: param-type-mismatch
    targetPos = EntityManager:getComponent(self.target, ComponentType.POSITION)
  else
    targetPos = self.target
  end
  if targetPos == nil then
    Logger:error("Attempted Task perform without target")
    return
  end
  local performerPos = EntityManager:getComponent(self.performer, ComponentType.POSITION)
  if performerPos == nil then
    Logger:error("Attempted Task perform without performer")
    return
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  if self:nearEnoughForTaskAction(targetPos, performerPos) then
    --- perform task ---
    local progress
    --- handle tasks related to target health ---
    if self.type >= TaskType.MINE and self.type <= TaskType.RESEARCH then
      --- self.target will only ever be an integer here.
      ---@diagnostic disable-next-line: param-type-mismatch
      local targetHealth = EntityManager:getComponent(self.target, ComponentType.HEALTH)
    end
  else
    --- create path to target ---
    local performerShape = EntityManager:getComponent(performerPos, ComponentType.SHAPE)
    local path = Pathfinder:findPath(entityPos:add(performerShape.size / 2, performerShape.size / 2), targetPos)
    if path ~= nil then
      TaskManager:newPath(performerPos, path)
    else
      Logger:error(
        "Path not created for entity at "
          .. performerPos.x
          .. ","
          .. performerPos.y
          .. " to target: "
          .. targetPos.x
          .. ","
          .. targetPos.y
      )
    end
  end
end

---@param v1 Vec2
---@param v2 Vec2
---@return boolean
function Task:nearEnoughForTaskAction(v1, v2)
  local diffX = math.abs(v1.x - v2.x)
  local diffY = math.abs(v1.y - v2.y)
  if diffX <= 1 and diffY <= 1 then
    return true
  end
  return false
end

return Task
