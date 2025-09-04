local enums = require("utils.enums")
local TopographyType = enums.TopographyType

---@class PathNode
---@field parent PathNode?    -- parent node (nil for the start node)
---@field position Vec2       -- world position of the node
---@field g number            -- cost from start
---@field h number            -- heuristic (goal‑to‑node)
---@field f number            -- g + h (priority)
---@field tileId number
---@field style TopographyType
local PathNode = {}
PathNode.__index = PathNode

--- Create (or reset) a node instance.
---@param parent PathNode? @the parent node (nil for the start)
---@param position Vec2   @the world position of this node
---@return PathNode node
function PathNode.new(parent, position)
	local self = setmetatable({}, PathNode)
	self.parent = parent
	self.position = position
	self.g = 0
	self.h = 0
	self.f = 0
	return self
end

--- Re‑initialise a pooled node for reuse.
function PathNode:reset()
	self.parent = nil
	self.position = nil
	self.g = 0
	self.h = 0
	self.f = 0
	self.tileId = nil
	self.style = TopographyType.OPEN
end

return PathNode
