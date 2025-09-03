--- @class MapManager
--- @field entityMgr     EntityManager
--- @field grid          table<number, table<number, number>>  -- [x][y] → entity‑id
--- @field width         integer
--- @field height        integer
--- @field graph         Graph?          -- nil until built
--- @field dirtyGraph    boolean
local MapManager = {}
MapManager.__index = MapManager

--- @param entityMgr   EntityManager
--- @param width       integer
--- @param height      integer
function MapManager.new(entityMgr, width, height)
  local self = setmetatable({}, MapManager)
  self.entityMgr = entityMgr
  self.grid = {} -- grid[x][y] → entity‑id
  self.width = width
  self.height = height
  self.graph = nil -- will hold the A* graph
  self.dirtyGraph = true -- first build is required
  return self
end

--- Spawn a new tile entity at (x, y).
--- @param x      integer
--- @param y      integer
--- @param style  TileStyle
--- @return number   entity‑id of the new tile
function MapManager:spawnTile(x, y, style)
  -- The concrete API of the entity manager is intentionally
  -- left generic – just assume it returns an entity id.
  local entityId = self.entityMgr:spawn("Tile", {
    components = {
      Position = { x = x, y = y },
      Topography = { style = style },
    },
  })

  self.grid[x] = self.grid[x] or {}
  self.grid[x][y] = entityId

  self.dirtyGraph = true
  return entityId
end

--- @param x          integer
--- @param y          integer
--- @param newStyle   TileStyle
function MapManager:setTileStyle(x, y, newStyle)
  local tileId = self.grid[x] and self.grid[x][y]
  if not tileId then
    return
  end

  local tile = self.entityMgr:get(tileId)
  tile.components.Topography.style = newStyle

  self.dirtyGraph = true
end

--- @class Graph
---   @field width  integer
---   @field height integer
---   @field nodes  table<number, table<number, PathNode>>

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
      local style = self:getTileStyle(x, y) or { walkable = true }
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

----------------------------------------------------------------
--  Quick lookup helpers
----------------------------------------------------------------

--- Retrieve a node from the current graph.
--- @param x integer
--- @param y integer
--- @return PathNode|nil
function MapManager:getNode(x, y)
  return self.graph and self.graph.nodes[x] and self.graph.nodes[x][y]
end

--- Convert a world position to grid indices.
--- @param pos Vec2
--- @return {x=integer, y=integer}
function MapManager:worldToGrid(pos)
  local gx = math.floor(pos.x / TILE_SIZE) + 1
  local gy = math.floor(pos.y / TILE_SIZE) + 1
  return { x = gx, y = gy }
end

--- Convert grid indices back to world coordinates (center of tile).
--- @param x integer
--- @param y integer
--- @return Vec2
function MapManager:gridToWorld(x, y)
  local wx = (x - 1) * TILE_SIZE + TILE_SIZE / 2
  local wy = (y - 1) * TILE_SIZE + TILE_SIZE / 2
  return Vec2.new(wx, wy)
end

----------------------------------------------------------------
--  Optional: style lookup helper
----------------------------------------------------------------

--- Get the style table for a tile (cached or read from its entity).
--- @param x integer
--- @param y integer
--- @return TileStyle|nil
function MapManager:getTileStyle(x, y)
  local tileId = self.grid[x] and self.grid[x][y]
  if not tileId then
    return nil
  end

  local tile = self.entityMgr:get(tileId)
  return tile.components.Topography.style
end

----------------------------------------------------------------
--  Export
----------------------------------------------------------------

return MapManager
