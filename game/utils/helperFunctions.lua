local Shape = require("components.Shape")
local Texture = require("components.Texture")
local Topography = require("components.Topography")
local Vec2 = require("utils.Vec2")
local TILE_SIZE = require("utils.constants").TILE_SIZE
local enums = require("utils.enums")
local TopographyType = enums.TopographyType
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType

local TopographyMap = {
  [TopographyType.OPEN] = 1.0,
  [TopographyType.ROUGH] = 0.5,
  [TopographyType.INACCESSIBLE] = 0,
}

local function getTopography()
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

---@param entityManager EntityManager
---@param xIndex integer
---@param yIndex integer
---@return unknown
local function createCell(entityManager, xIndex, yIndex)
  local result = getTopography()

  local tileId = entityManager:createEntity()

  entityManager:addComponent(
    tileId,
    ComponentType.POSITION,
    Vec2.new((xIndex - 1) * TILE_SIZE, (yIndex - 1) * TILE_SIZE)
  )
  entityManager:addComponent(tileId, ComponentType.TEXTURE, Texture.new(result.color))
  entityManager:addComponent(tileId, ComponentType.SHAPE, Shape.new(ShapeType.SQUARE, TILE_SIZE))
  entityManager:addComponent(tileId, ComponentType.TOPOGRAPHY, Topography.new(result.style, result.speedMultiplier))
  entityManager:addComponent(tileId, ComponentType.MAPTILETAG, Vec2.new(xIndex, yIndex))
  return tileId
end

local function buildGraph(entityManager)
  local pos = entityManager.components[ComponentType.POSITION]
  local topo = entityManager.components[ComponentType.TOPOGRAPHY]
  local tag = entityManager.components[ComponentType.MAPTILETAG]

  -- determine bounds
  local width, height = 0, 0
  for id, p in pairs(pos) do
    if tag[id] then
      width = math.max(width, p.x)
      height = math.max(height, p.y)
    end
  end

  -- allocate contiguous arrays
  local graph = {
    nodes = {}, -- nodes[i] = {entityId, walkable, neighbors = {…}}
    width = width,
    height = height,
  }

  -- fill nodes array
  for x = 1, width do
    graph.nodes[x] = {}
    for y = 1, height do
      local id = tileGrid[x][y] -- you already built this during spawn
      if id and topo[id] and topo[id].style ~= TopographyType.INACCESSIBLE then
        -- walkable
        graph.nodes[x][y] = {
          id = id,
          pos = pos[id], -- world position
          neighbors = {}, -- to be filled
        }
      end
    end
  end

  -- pre‑compute the neighbor lists (static!)
  for x = 1, width do
    for y = 1, height do
      local node = graph.nodes[x][y]
      if node then
        for dx = -1, 1 do
          for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
              local nx, ny = x + dx, y + dy
              if nx >= 1 and nx <= width and ny >= 1 and ny <= height then
                local nb = graph.nodes[nx][ny]
                if nb then
                  table.insert(node.neighbors, nb)
                end
              end
            end
          end
        end
      end
    end
  end

  return graph
end
---
---@param entityManager EntityManager
---@param width integer
---@param height integer
---@return table -- Graph of the created map
local function createLevelMap(entityManager, width, height)
  local tiles = {}
  for y = 1, height do
    for x = 1, width do
      local tileId = createCell(entityManager, x, y)
      table.insert(tiles, tileId)
    end
  end
  return buildGraph(entityManager)
end

local function compareTables(a, b)
  if a == b then
    return true
  end -- same reference
  if type(a) ~= "table" or type(b) ~= "table" then
    return false
  end

  for k, v in pairs(a) do
    if not compareTables(v, b[k]) then
      return false
    end
  end

  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end

  return true
end

return {
  createLevelMap = createLevelMap,
  compareTables = compareTables,
  buildGraph = buildGraph,
}
