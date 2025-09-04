local Vec2 = require("utils.Vec2")
local constants = require("utils.constants")
local PathNode = require("components.PathNode")
local Topography = require("components.Topography")
local Shape = require("components.Shape")
local Texture = require("components.Texture")
local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TopographyType = enums.TopographyType

--- @class Graph
--- @field width  integer
--- @field height integer
--- @field nodes  table<number, table<number, PathNode>>

--- @class MapManager
--- @field entityManager     EntityManager
--- @field grid          table<number, table<number, number>>  -- [x][y] → entity‑id
--- @field width         integer
--- @field height        integer
--- @field tiles		 integer[]
--- @field graph         Graph?          -- nil until built
--- @field dirtyGraph    boolean
local MapManager = {}
MapManager.__index = MapManager

--- @param entityManager   EntityManager
--- @param width       integer
--- @param height      integer
function MapManager.new(entityManager, width, height)
	local self = setmetatable({}, MapManager)
	self.entityManager = entityManager
	self.tiles = {}
	self.grid = {} -- grid[x][y] → entity‑id
	self.width = width
	self.height = height
	self.graph = nil -- will hold the A* graph
	self.dirtyGraph = true -- first build is required
	return self
end

local TopographyMap = {
	[TopographyType.OPEN] = 1.0,
	[TopographyType.ROUGH] = 0.5,
	[TopographyType.INACCESSIBLE] = 0,
}

function MapManager:rollTopography()
	local val = math.random()
	if val < 0.5 then
		return {
			style = TopographyType.OPEN,
			speedMultiplier = TopographyMap[TopographyType.OPEN],
			color = { r = 0.0, g = 1.0, b = 0.0 },
		}
	elseif val < 0.85 then
		return {
			style = TopographyType.ROUGH,
			speedMultiplier = TopographyMap[TopographyType.ROUGH],
			color = { r = 0.0, g = 0.0, b = 1.0 },
		}
	else
		return {
			style = TopographyType.INACCESSIBLE,
			speedMultiplier = TopographyMap[TopographyType.INACCESSIBLE],
			color = { r = 1.0, g = 0.0, b = 0.0 },
		}
	end
end

---@param xIndex integer
---@param yIndex integer
---@return integer
function MapManager:createCell(xIndex, yIndex)
	local result = self:rollTopography()

	local tileId = self.entityManager:createEntity()

	self.entityManager:addComponent(
		tileId,
		ComponentType.POSITION,
		Vec2.new((xIndex - 1) * constants.pixelSize, (yIndex - 1) * constants.pixelSize)
	)
	self.entityManager:addComponent(tileId, ComponentType.TEXTURE, Texture.new(result.color))
	self.entityManager:addComponent(tileId, ComponentType.SHAPE, Shape.new(ShapeType.SQUARE, constants.pixelSize))
	self.entityManager:addComponent(
		tileId,
		ComponentType.TOPOGRAPHY,
		Topography.new(result.style, result.speedMultiplier)
	)
	self.entityManager:addComponent(tileId, ComponentType.MAPTILETAG, Vec2.new(xIndex, yIndex))
	return tileId
end

---@param entityManager EntityManager
---@param width integer
---@param height integer
function MapManager:createLevelMap(width, height)
	local tiles = {}
	for y = 1, height do
		for x = 1, width do
			local tileId = self:createCell(x, y)
			table.insert(tiles, tileId)
		end
	end
	self.tiles = tiles
	self:buildGraph()
end

--- Spawn a new tile entity at (x, y).
--- @param x      integer
--- @param y      integer
--- @param style  TopographyType
--- @return number   entity‑id of the new tile
function MapManager:spawnTile(x, y, style)
	local entityId = self.entityManager:createEntity()
	self.entityManager:addComponent(entityId, ComponentType.POSITION, Vec2.new(x, y))
	self.entityManager:addComponent(entityId, ComponentType.TOPOGRAPHY, style)

	self.grid[x] = self.grid[x] or {}
	self.grid[x][y] = entityId

	self.dirtyGraph = true
	return entityId
end

--- @param x          integer
--- @param y          integer
--- @param newStyle   TopographyType
function MapManager:updateTileStyle(x, y, newStyle)
	local tileId = self.grid[x] and self.grid[x][y]
	if not tileId then
		return
	end

	local tile = self.entityManager:getComponent(tileId, ComponentType.TOPOGRAPHY)
	tile.components.Topography.style = newStyle

	self.dirtyGraph = true
end

--- Build (or rebuild) the entire graph from the current grid.
--- @return nil
function MapManager:buildGraph()
	local graph = {
		width = self.width,
		height = self.height,
		nodes = {}, -- [x][y] → PathNode
	}

	-- 1️⃣ Create a node for every tile
	for x = 1, self.width do
		graph.nodes[x] = {}
		for y = 1, self.height do
			local tileId = self.grid[x] and self.grid[x][y]
			local node = PathNode.new(nil, Vec2.new(x, y))
			node.tileId = tileId

			-- Pull style from the entity (or a cached map)
			local style = self:getTileStyle(x, y) or Top
			node.style = style
			graph.nodes[x][y] = node
		end
	end

	-- 2️⃣ Compute 4‑way adjacency lists
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	for x = 1, self.width do
		for y = 1, self.height do
			local node = graph.nodes[x][y]
			node.neighbors = {}

			for _, d in ipairs(dirs) do
				local nx, ny = x + d[1], y + d[2]
				if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
					local neighbour = graph.nodes[nx][ny]
					if neighbour.style.walkable then
						table.insert(node.neighbors, neighbour)
					end
				end
			end
		end
	end

	self.graph = graph
	self.dirtyGraph = false
end

--- Rebuild the graph only when dirty – call once per frame.
--- @return nil
function MapManager:update()
	if self.dirtyGraph then
		self:buildGraph()
	end
end

--- Retrieve a node from the current graph.
--- @param x integer
--- @param y integer
--- @return PathNode|nil
function MapManager:getNode(x, y)
	return self.graph and self.graph.nodes[x] and self.graph.nodes[x][y]
end

--- Convert a world position to grid indices.
--- @param pos Vec2
--- @return Vec2
function MapManager:worldToGrid(pos)
	local x = math.floor(pos.x / constants.pixelSize) + 1
	local y = math.floor(pos.y / constants.pixelSize) + 1
	return Vec2.new(x, y)
end

--- Convert grid indices back to world coordinates (center of tile).
--- @param x integer
--- @param y integer
--- @return Vec2
function MapManager:gridToWorld(x, y)
	local wx = (x - 1) * constants.pixelSize + constants.pixelSize / 2
	local wy = (y - 1) * constants.pixelSize + constants.pixelSize / 2
	return Vec2.new(wx, wy)
end

--- Get the style table for a tile (cached or read from its entity).
--- @param x integer
--- @param y integer
--- @return TopographyType|nil
function MapManager:getTileStyle(x, y)
	local tileId = self.grid[x] and self.grid[x][y]
	if not tileId then
		return nil
	end

	local tile = self.entityManager:getComponent(tileId, ComponentType.TOPOGRAPHY)

	return tile.components.Topography
end

return MapManager
