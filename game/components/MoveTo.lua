local Vec2 = require("game.utils.Vec2")
local enums = require("game.utils.enums")
local ComponentType = enums.ComponentType

---@class MoveTo
---@field target Vec2
local MoveTo = {}
MoveTo.__index = MoveTo

---@param target Vec2
---@return MoveTo
function MoveTo.new(target)
  local self = setmetatable({}, MoveTo)
  self.target = target
  return self
end
