local Vec2 = require("utils.Vec2")
local constants = require("utils.constants")
local Tile = require("components.Tile")

---@class Pathfinder
---@field nodePool table<integer, Tile>
---@field poolIndex integer
local PathFinder = {}
PathFinder.__index = PathFinder

--- Create a new, empty Pathfinder instance.
--- @return Pathfinder
function PathFinder.new()
	local self = setmetatable({}, PathFinder)
	self.nodePool = {}
	self.poolIndex = 1
	return self
end

---Return all pooled nodes to the pool and reset the index.
function PathFinder:releaseAll()
	self.nodePool = {}
	self.poolIndex = 1
end

---Grab a node from the pool (or create a new one) and init its bookkeeping fields.
---@param parent Tile?          -- parent node (nil for the start node)
---@param position Vec2          -- world position of the node
---@return table node            -- a reused node table
function PathFinder:obtainNode(parent, position)
	local n = self.nodePool[self.poolIndex]
	if n then
		self.poolIndex = self.poolIndex + 1
	else
		n = Tile.new(parent, position) -- first use, node creation
	end
	n.parent = parent
	n.position = position
	n.g = 0
	n.h = 0
	n.f = 0
	return n
end

---Insert a node into the min‑heap.
---@param heap   table<integer,Tile>   -- binary heap (min‑heap on `f`)
---@param node   table                  -- node to insert
function PathFinder:heapPush(heap, node)
	local i = #heap + 1
	heap[i] = node
	while i > 1 do
		local p = math.floor(i / 2)
		if heap[p].f <= heap[i].f then
			break
		end
		heap[i], heap[p] = heap[p], heap[i]
		i = p
	end
end

---@param heap table<integer,table>   -- binary heap
---@return table? -- node with the smallest `f` value
function PathFinder:heapPop(heap)
	if #heap == 0 then
		return nil
	end
	local min = heap[1]
	heap[1] = heap[#heap]
	heap[#heap] = nil
	local i = 1
	while true do
		local l = i * 2
		local r = l + 1
		if l > #heap then
			break
		end
		local smallest = l
		if r <= #heap and heap[r].f < heap[l].f then
			smallest = r
		end
		if heap[i].f <= heap[smallest].f then
			break
		end
		heap[i], heap[smallest] = heap[smallest], heap[i]
		i = smallest
	end
	return min
end

---@param startWorldPos Vec2
---@param endWorldPos Vec2
---@param mapManager MapManager
function PathFinder:findPath(startWorldPos, endWorldPos, mapManager)
	local startVec = mapManager:worldToGrid(startWorldPos)
	local endVec = mapManager:worldToGrid(endWorldPos)

	local startNode = mapManager.graph[startVec.x][startVec.y]
	local goalNode = mapManager.graph[endVec.x][endVec.y]

	if not startNode or not goalNode then
		return nil
	end

	-- Open / closed sets
	local open = {}
	local closedSet = {}
	for x = 1, #mapManager.graph do
		closedSet[x] = {}
	end

	local function isInOpenSet(node)
		for _, openNode in ipairs(open) do
			if openNode.position.x == node.position.x and openNode.position.y == node.position.y then
				return true
			end
		end
		return false
	end

	local function pushNode(node)
		node.g = node.parent and node.parent.g + 1 or 0
		node.h = (node.position.x - goalNode.position.x) ^ 2 + (node.position.y - goalNode.position.y) ^ 2
		node.f = node.g + node.h
		self:heapPush(open, node)
	end

	local start = self:obtainNode(nil, startNode.position)
	pushNode(start)

	while #open > 0 do
		local current = self:heapPop(open)
		if current == nil then
			Logger:error("There was no node in the open set, this should never happen")
			return nil
		end

		closedSet[current.position.x][current.position.y] = true

		if current.position.x == goalNode.position.x and current.position.y == goalNode.position.y then
			local path = {}
			local n = current
			while n do
				table.insert(path, 1, n.position)
				n = n.parent
			end
			self:releaseAll()
			return path
		end

		local currentNode = mapManager.graph[current.position.x][current.position.y]
		for _, nbNode in ipairs(currentNode.neighbors or {}) do
			if not closedSet[nbNode.position.x][nbNode.position.y] and not isInOpenSet(nbNode) then
				local child = self:obtainNode(current, nbNode.position)
				pushNode(child)
			end
		end
	end

	self:releaseAll()
	return nil -- Explicitly return nil if no path is found
end

return PathFinder.new()
