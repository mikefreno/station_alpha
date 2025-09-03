local Vec2 = require("utils.Vec2")
local TILE_SIZE = require("utils.constants").TILE_SIZE
local enums = require("utils.enums")
local ShapeType = enums.ShapeType
local ComponentType = enums.ComponentType
local PathNode = require("utils.PathNode")

---@class Pathfinder
---@field nodePool table<integer, PathNode>
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
---@param parent PathNode?          -- parent node (nil for the start node)
---@param position Vec2          -- world position of the node
---@return table node            -- a reused node table
function PathFinder:obtainNode(parent, position)
  local n = self.nodePool[self.poolIndex]
  if n then
    self.poolIndex = self.poolIndex + 1
  else
    n = PathNode.new(parent, position) -- first use, node creation
  end
  n.parent = parent
  n.position = position
  n.g = 0
  n.h = 0
  n.f = 0
  return n
end

---Insert a node into the min‑heap.
---@param heap   table<integer,PathNode>   -- binary heap (min‑heap on `f`)
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
---@param graph any
---@return nil
function PathFinder:findPath(startWorldPos, endWorldPos, graph)
  local function worldToGrid(v)
    return {
      x = math.floor(v.x / TILE_SIZE) + 1,
      y = math.floor(v.y / TILE_SIZE) + 1,
    }
  end

  local startIdx = worldToGrid(startWorldPos)
  local endIdx = worldToGrid(endWorldPos)

  local startNode = graph.nodes[startIdx.x][startIdx.y]
  local goalNode = graph.nodes[endIdx.x][endIdx.y]

  if not startNode or not goalNode then
    return nil
  end

  -- Open / closed sets
  local open = {}
  local closedSet = {}
  for x = 1, graph.width do
    closedSet[x] = {}
  end

  local function pushNode(node)
    node.g = node.parent and node.parent.g + 1 or 0
    node.h = (node.position.x - goalNode.position.x) ^ 2 + (node.position.y - goalNode.position.y) ^ 2
    node.f = node.g + node.h
    self:heapPush(open, node)
  end

  local start = self:obtainNode(nil, startNode.pos)
  pushNode(start)

  while #open > 0 do
    local current = self:heapPop(open)
    if current == nil then
      Logger:error("There was no node in the open set, this should never happen")
      return nil
    end
    local idx = worldToGrid(current.position)
    closedSet[idx.x][idx.y] = true

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

    local currentNode = graph.nodes[idx.x][idx.y]
    for _, nbNode in ipairs(currentNode.neighbors or {}) do
      local nIdx = worldToGrid(nbNode.pos)
      if not closedSet[nIdx.x][nIdx.y] then
        local child = self:obtainNode(current, nbNode.pos)
        pushNode(child)
      end
    end
  end

  self:releaseAll()
  return nil
end

return PathFinder.new()
