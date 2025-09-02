local enums = require("utils.enums")
local ShapeType = enums.ShapeType

---@class Shape
---@field shape ShapeType
---@field size number
local Shape = {}
Shape.__index = Shape

---@param shape ShapeType
---@param size number
function Shape.new(shape, size)
	local self = setmetatable({}, Shape)
	self.shape = shape
	self.size = size
	return self
end

return Shape
