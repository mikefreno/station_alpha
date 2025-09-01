local Vec2 = require("utils.Vec2")
local TILE_SIZE = require("utils.constants").TILE_SIZE
local enums = require("utils.enums")
local Shapes = enums.Shapes
local ComponentType = enums.ComponentType

local PathFinder = {}
PathFinder.__index = PathFinder

--- Simple A* implementation
function PathFinder.new()
	return setmetatable({}, PathFinder)
end

--- @param entityManager EntityManager
--- @param startEntity integer  -- entity that should start moving
--- @param goalEntity integer|Vec2   -- entity that represents the target (must have POSITION)
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
	local goalPos = goalEntity
	if type(goalEntity) == "number" then
		goalPos = getPosition(goalEntity)
	end
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

	local function costOf(cell)
		if cell.speedMultiplier == 0 then
			return math.huge -- block the tile
		end
		-- you can decide whether to use integer or floating cost
		return 1 / cell.speedMultiplier -- float
		-- or: return math.ceil(1 / cell.speedMultiplier)  -- integer
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
			local nx, ny = current.x + d.dx, current.y + d.dy
			if nx >= 1 and nx <= width and ny >= 1 and ny <= height then
				local neighbour = { x = nx, y = ny }
				local cell = entityManager:find(ComponentType.POSITION, neighbour) -- fetch the MapCell
				local stepCost = costOf(cell)

				-- skip impassable tiles
				if stepCost == math.huge then
					goto continue
				end

				local newCost = costSoFar[key(current)] + stepCost
				if not costSoFar[key(neighbour)] or newCost < costSoFar[key(neighbour)] then
					costSoFar[key(neighbour)] = newCost
					local priority = newCost + (math.abs(goalTile.x - nx) + math.abs(goalTile.y - ny))
					push(frontier, neighbour, priority)
					cameFrom[key(neighbour)] = current
				end
			end
			::continue::
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
