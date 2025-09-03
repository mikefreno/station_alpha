-- =================================================================
-- A lightweight node class used by the Pathfinder.
--
-- It is intentionally simple: the Pathfinder owns the memory pool,
-- so the node instance is just a plain table with a tiny helper method.
-- =================================================================

local Vec2 = require("utils.Vec2")

---@class PathNode
---@field parent PathNode?    -- parent node (nil for the start node)
---@field position Vec2       -- world position of the node
---@field g number            -- cost from start
---@field h number            -- heuristic (goal‑to‑node)
---@field f number            -- g + h (priority)
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
---@return void
function PathNode:reset()
  self.parent = nil
  self.position = nil
  self.g = 0
  self.h = 0
  self.f = 0
end

return PathNode
