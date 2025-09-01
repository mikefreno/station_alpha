local Vec2 = require("utils.Vec2")
local TILE_SIZE = require("utils.constants").TILE_SIZE
local Shapes = require("utils.enums").Shapes
local ComponentType = require("utils.enums").ComponentType

local PathFinder = {}
PathFinder.__index = PathFinder

--- Simple A* implementation
function PathFinder.new()
	return setmetatable({}, PathFinder)
end

--- @param entityManager EntityManager
--- @param startEntity integer  -- entity that should start moving
--- @param goalEntity integer   -- entity that represents the target (must have POSITION)
--- @return table
function PathFinder:findPath(entityManager, startEntity, goalEntity)
	local function getPosition(id)
		local p = entityManager:getComponent(id, ComponentType.POSITION)
		return Vec2.new(p.x, p.y)
	end

	-- Build a 2‑D array of tile indices (entity ids) for fast lookup
	local width, height = self:_gridDimensions(entityManager)
	local grid = {}
	for y = 1, height do
		grid[y] = {}
	end
	for _, e in ipairs(entityManager.entities) do
		local shape = entityManager:getComponent(e, ComponentType.SHAPE)
		if shape and shape.shape == Shapes.SQUARE then
			grid[(e - 1) / width + 1] = e -- but we’ll ignore actual tile id; we just need the coordinates
		end
	end

	-- Convert world positions to tile indices
	local function worldToTile(v)
		return {
			x = math.floor(v.x / TILE_SIZE) + 1,
			y = math.floor(v.y / TILE_SIZE) + 1,
		}
	end

	local startPos = getPosition(startEntity)
	local goalPos = getPosition(goalEntity)
	local startTile = worldToTile(startPos)
	local goalTile = worldToTile(goalPos)

	-- Helper for neighbour tiles (4‑connected)
	local neighbours = {
		{ dx = 1, dy = 0 },
		{ dx = -1, dy = 0 },
		{ dx = 0, dy = 1 },
		{ dx = 0, dy = -1 },
	}

	-- A* priority queue (min‑heap)
	local frontier = {}
	local cameFrom = {}
	local costSoFar = {}

	local function push(q, node, priority)
		table.insert(q, { node = node, priority = priority })
		table.sort(q, function(a, b)
			return a.priority < b.priority
		end)
	end

	local function pop(q)
		return table.remove(q, 1).node
	end

	local function key(t)
		return t.x .. "," .. t.y
	end

	-- init
	push(frontier, startTile, 0)
	cameFrom[key(startTile)] = nil
	costSoFar[key(startTile)] = 0

	local found = false

	while #frontier > 0 do
		local current = pop(frontier)

		if current.x == goalTile.x and current.y == goalTile.y then
			found = true
			break
		end

		for _, d in ipairs(neighbours) do
			local nextT = { x = current.x + d.dx, y = current.y + d.dy }
			if nextT.x >= 1 and nextT.x <= width and nextT.y >= 1 and nextT.y <= height then
				-- No obstacle check for now (you can add collision mask)
				local newCost = costSoFar[key(current)] + 1
				if not costSoFar[key(nextT)] or newCost < costSoFar[key(nextT)] then
					costSoFar[key(nextT)] = newCost
					local priority = newCost + (math.abs(goalTile.x - nextT.x) + math.abs(goalTile.y - nextT.y))
					push(frontier, nextT, priority)
					cameFrom[key(nextT)] = current
				end
			end
		end
	end

	if not found then
		return {}
	end

	-- Reconstruct path
	local path = {}
	local t = goalTile
	while t do
		table.insert(path, 1, Vec2.new((t.x - 1) * TILE_SIZE + TILE_SIZE / 2, (t.y - 1) * TILE_SIZE + TILE_SIZE / 2))
		t = cameFrom[key(t)]
	end
	return path
end

-- Utility: deduce map size (you can store width/height in a component)
function PathFinder:_gridDimensions(entityManager)
	local maxX, maxY = 0, 0
	for e, _ in pairs(entityManager.entities) do
		local p = entityManager.components[ComponentType.POSITION]
			and entityManager.components[ComponentType.POSITION][e]
		if p then
			if p.x > maxX then
				maxX = p.x
			end
			if p.y > maxY then
				maxY = p.y
			end
		end
	end
	return math.floor(maxX / TILE_SIZE) + 1, math.floor(maxY / TILE_SIZE) + 1
end

return PathFinder.new()
