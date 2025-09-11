local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

---@class Pathfinder
---@field nodePool table<integer, table> -- pool of plain node tables
---@field poolIndex integer
local PathFinder = {}
PathFinder.__index = PathFinder

function PathFinder.new()
  local self = setmetatable({}, PathFinder)
  self.nodePool = {}
  self.poolIndex = 1
  return self
end

function PathFinder:releaseAll()
  self.nodePool = {}
  self.poolIndex = 1
end

-- obtainNode creates/reuses plain node tables (do NOT call Tile.new here)
function PathFinder:obtainNode(parent, position)
  local n = self.nodePool[self.poolIndex]
  if n then
    self.poolIndex = self.poolIndex + 1
  else
    n = { parent = nil, position = nil, g = 0, h = 0, f = 0 }
  end
  n.parent = parent
  n.position = position -- position is a Vec2 grid index (tile.position)
  n.g = 0
  n.h = 0
  n.f = 0
  return n
end

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

---@param startWorldPos Vec2  -- top left pos
---@param endWorldPos Vec2    -- same as above
function PathFinder:findPath(startWorldPos, endWorldPos)
  if not MapManager or not MapManager.graph or not MapManager.graph[1] then
    Logger:error("MapManager error")
    return nil
  end

  local function ensureGrid(v)
    if not v then
      return nil
    end
    if v.x and v.y and v.x >= 1 and v.x <= MapManager.width and v.y >= 1 and v.y <= MapManager.height then
      return v
    end
    return MapManager:worldToGrid(v)
  end

  local startGrid = ensureGrid(startWorldPos)
  local endGrid = ensureGrid(endWorldPos)
  if not startGrid or not endGrid then
    Logger:error("start/end vec error")
    return nil
  end

  if
    startGrid.x < 1
    or startGrid.x > MapManager.width
    or startGrid.y < 1
    or startGrid.y > MapManager.height
    or endGrid.x < 1
    or endGrid.x > MapManager.width
    or endGrid.y < 1
    or endGrid.y > MapManager.height
  then
    Logger:error("bounds exceeded")
    return nil
  end

  local startTile = MapManager.graph[math.floor(startGrid.x)]
    and MapManager.graph[math.floor(startGrid.x)][math.floor(startGrid.y)]
  local goalTile = MapManager.graph[endGrid.x] and MapManager.graph[endGrid.x][endGrid.y]
  if not startTile or not goalTile then
    Logger:error("start/end node error")
    return nil
  end

  -- Helper: get tile speed multiplier (returns number > 0). Prefer Tile.speedMultiplier, fallback to entity component.
  local function getSpeedMultiplier(tile)
    if not tile then
      return 0
    end
    if tile.speedMultiplier and type(tile.speedMultiplier) == "number" then
      return tile.speedMultiplier
    end
    if tile.id and MapManager.entityManager then
      local topo = MapManager.entityManager:getComponent(tile.id, ComponentType.TOPOGRAPHY)
      if topo and topo.speedMultiplier then
        return topo.speedMultiplier
      end
    end
    -- default to OPEN speed 1.0 if missing
    return 1.0
  end

  -- movement cost per step when traversing a tile = 1 / speedMultiplier
  local function moveCostForTile(tile)
    local sm = getSpeedMultiplier(tile)
    if not sm or sm <= 0 then
      return math.huge -- impassable or invalid
    end
    return 1.0 / sm
  end

  -- heuristic: use Manhattan distance times minimum move cost (admissible).
  -- Minimum move cost is 1 / maxSpeedMultiplier. We assume maxSpeedMultiplier is 1.0 (OPEN).
  local minMoveCost = 1.0 -- if OPEN is fastest (speedMultiplier==1), moveCost = 1
  local function heuristic(px, py)
    local dx = math.abs(px - goalTile.position.x)
    local dy = math.abs(py - goalTile.position.y)
    return (dx + dy) * minMoveCost
  end

  -- open list and closed set
  local open = {}
  local closedSet = {}
  for x = 1, MapManager.width do
    closedSet[x] = {}
    for y = 1, MapManager.height do
      closedSet[x][y] = false
    end
  end

  local startNode = self:obtainNode(nil, startTile.position)
  startNode.g = 0
  startNode.h = heuristic(startNode.position.x, startNode.position.y)
  startNode.f = startNode.g + startNode.h
  self:heapPush(open, startNode)

  while #open > 0 do
    local current = self:heapPop(open)
    if not current then
      Logger:error("empty open set")
      return nil
    end

    local cx, cy = current.position.x, current.position.y
    if not closedSet[cx] or closedSet[cx][cy] == nil then
      Logger:error("Invalid position in closedSet: x:" .. tostring(cx) .. ", y:" .. tostring(cy))
      return nil
    end

    closedSet[cx][cy] = true

    local function isStart(n)
      if n.parent == nil then
        return true
      end
      if n.position.x == math.floor(startWorldPos.x) and n.position.y == math.floor(startWorldPos.y) then
        return true
      end
      return false
    end

    if cx == goalTile.position.x and cy == goalTile.position.y then
      local path = {}
      local n = current
      while n do
        if not isStart(n) then
          table.insert(path, 1, { type = TaskType.MOVETO, data = n.position })
        end
        n = n.parent
      end
      self:releaseAll()
      return path
    end

    local currentTile = MapManager.graph[cx] and MapManager.graph[cx][cy]
    if not currentTile then
      goto continue_main
    end

    for _, nb in ipairs(currentTile.neighbors or {}) do
      if not nb.position or not nb.position.x or not nb.position.y then
        goto continue_neighbor
      end
      local nx, ny = nb.position.x, nb.position.y
      if not MapManager.graph[nx] or not MapManager.graph[nx][ny] then
        goto continue_neighbor
      end
      if closedSet[nx][ny] then
        goto continue_neighbor
      end

      -- compute tentative g using move cost to enter neighbor
      local tentativeCost = current.g + moveCostForTile(nb)
      -- check if neighbor already in open with better g
      local inOpen = false
      for _, on in ipairs(open) do
        if on.position.x == nx and on.position.y == ny then
          inOpen = true
          if tentativeCost < (on.g or math.huge) then
            -- better path found: update parent and costs, then re-heapify by pushing updated node
            on.parent = current
            on.g = tentativeCost
            on.h = heuristic(nx, ny)
            on.f = on.g + on.h
            -- reinsert: simplest is to push again (heap may contain old node but comparator uses f)
            self:heapPush(open, on)
          end
          break
        end
      end

      if not inOpen then
        local child = self:obtainNode(current, nb.position)
        child.g = tentativeCost
        child.h = heuristic(nx, ny)
        child.f = child.g + child.h
        self:heapPush(open, child)
      end

      ::continue_neighbor::
    end

    ::continue_main::
  end

  self:releaseAll()
  return nil
end

return PathFinder
