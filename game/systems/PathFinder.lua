local Tile = require("components.Tile")

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

---@param startWorldPos Vec2
---@param endWorldPos Vec2
---@param mapManager MapManager
function PathFinder:findPath(startWorldPos, endWorldPos, mapManager)
    if not mapManager or not mapManager.graph or not mapManager.graph[1] then
        Logger:error("mapManager error")
        return nil
    end

    local startGrid = mapManager:worldToGrid(startWorldPos)
    local endGrid = mapManager:worldToGrid(endWorldPos)
    if not startGrid or not endGrid then
        Logger:error("start/end vec error")
        return nil
    end

    if
        startGrid.x < 1
        or startGrid.x > mapManager.width
        or startGrid.y < 1
        or startGrid.y > mapManager.height
        or endGrid.x < 1
        or endGrid.x > mapManager.width
        or endGrid.y < 1
        or endGrid.y > mapManager.height
    then
        Logger:error("bounds exceeded")
        return nil
    end

    -- get start/goal tiles (graph[x][y])
    local startTile = mapManager.graph[startGrid.x]
        and mapManager.graph[startGrid.x][startGrid.y]
    local goalTile = mapManager.graph[endGrid.x]
        and mapManager.graph[endGrid.x][endGrid.y]
    if not startTile or not goalTile then
        Logger:error("start/end node error")
        return nil
    end

    -- open list and closed set (closedSet[x][y])
    local open = {}
    local closedSet = {}
    for x = 1, mapManager.width do
        closedSet[x] = {}
        for y = 1, mapManager.height do
            closedSet[x][y] = false
        end
    end

    local function isInOpen(px, py)
        for _, n in ipairs(open) do
            if n.position.x == px and n.position.y == py then
                return true
            end
        end
        return false
    end

    local function pushNode(node)
        node.g = node.parent and node.parent.g + 1 or 0
        node.h = (node.position.x - goalTile.position.x) ^ 2
            + (node.position.y - goalTile.position.y) ^ 2
        node.f = node.g + node.h
        self:heapPush(open, node)
    end

    -- Start node uses tile.position (grid Vec2)
    local startNode = self:obtainNode(nil, startTile.position)
    pushNode(startNode)

    while #open > 0 do
        local current = self:heapPop(open)
        if not current then
            Logger:error("empty open set")
            return nil
        end

        local cx, cy = current.position.x, current.position.y
        if not closedSet[cx] or closedSet[cx][cy] == nil then
            Logger:error(
                "Invalid position in closedSet: x:"
                    .. tostring(cx)
                    .. ", y:"
                    .. tostring(cy)
            )
            return nil
        end

        closedSet[cx][cy] = true

        -- goal reached?
        if cx == goalTile.position.x and cy == goalTile.position.y then
            local path = {}
            local n = current
            while n do
                -- return tile.position Vec2s (grid indices); caller converts to world if needed
                table.insert(path, 1, n.position)
                n = n.parent
            end
            self:releaseAll()
            return path
        end

        local currentTile = mapManager.graph[cx] and mapManager.graph[cx][cy]
        if not currentTile then
            goto continue_main
        end

        for _, nb in ipairs(currentTile.neighbors or {}) do
            -- neighbor.position is Tile.position (Vec2 of grid indices)
            if not nb.position or not nb.position.x or not nb.position.y then
                Logger:debug("Neighbor missing position; skipping")
                goto continue_neighbor
            end

            local nx, ny = nb.position.x, nb.position.y

            if not mapManager.graph[nx] or not mapManager.graph[nx][ny] then
                goto continue_neighbor
            end

            if not closedSet[nx][ny] and not isInOpen(nx, ny) then
                local child = self:obtainNode(current, nb.position)
                pushNode(child)
            end

            ::continue_neighbor::
        end

        ::continue_main::
    end

    self:releaseAll()
    return nil
end

return PathFinder.new()
