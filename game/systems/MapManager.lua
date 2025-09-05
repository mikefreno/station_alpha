local Vec2 = require("utils.Vec2")
local constants = require("utils.constants")
local Topography = require("components.Topography")
local Shape = require("components.Shape")
local Texture = require("components.Texture")
local enums = require("utils.enums")
local Tile = require("components.Tile")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local TopographyType = enums.TopographyType

--- @class MapManager
--- @field entityManager     EntityManager
--- @field width         integer
--- @field height        integer
--- @field graph         table<number, table<number, Tile>> -- graph[x][y]
--- @field dirtyGraph    boolean
local MapManager = {}
MapManager.__index = MapManager

--- @param entityManager   EntityManager
--- @param width       integer
--- @param height      integer
function MapManager.new(entityManager, width, height)
    local self = setmetatable({}, MapManager)
    self.entityManager = entityManager
    self.width = width
    self.height = height
    self.graph = {} -- will hold the A* graph as graph[x][y]
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
    -- for simple testing purposes, as even this is failing
    if val < 1 then
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
---@return integer entityId
function MapManager:createCell(xIndex, yIndex)
    local result = self:rollTopography()

    local tileId = self.entityManager:createEntity()

    -- store world position as top-left of tile (consistent with tests / createCell usage)
    self.entityManager:addComponent(
        tileId,
        ComponentType.POSITION,
        Vec2.new((xIndex - 1) * constants.pixelSize, (yIndex - 1) * constants.pixelSize)
    )
    self.entityManager:addComponent(
        tileId,
        ComponentType.TEXTURE,
        Texture.new(result.color)
    )
    self.entityManager:addComponent(
        tileId,
        ComponentType.SHAPE,
        Shape.new(ShapeType.SQUARE, constants.pixelSize)
    )
    self.entityManager:addComponent(
        tileId,
        ComponentType.TOPOGRAPHY,
        Topography.new(result.style, result.speedMultiplier)
    )
    -- store grid tag as x,y indices
    self.entityManager:addComponent(
        tileId,
        ComponentType.MAPTILETAG,
        Vec2.new(xIndex, yIndex)
    )
    return tileId
end

function MapManager:createLevelMap()
    -- Build graph as graph[x][y] to match PathFinder expectations
    local tiles = {}
    for x = 1, self.width do
        tiles[x] = {}
        for y = 1, self.height do
            local tileId = self:createCell(x, y)
            local tile = Tile.new(x, y, tileId)
            -- Ensure tile exposes grid indices (x,y) so consumers can read them easily
            tile.x = x
            tile.y = y
            tiles[x][y] = tile
        end
    end
    self.graph = tiles -- Now it's a 2D grid of Tiles indexed as graph[x][y]
    self:buildGraph()
end

function MapManager:buildGraph()
    local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } -- orthogonal only
    for x = 1, self.width do
        for y = 1, self.height do
            local tile = self.graph[x][y]
            tile.neighbors = {}
            for _, d in ipairs(dirs) do
                local nx, ny = x + d[1], y + d[2]
                if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
                    local neighbor = self.graph[nx][ny]
                    -- Read topography from entity component if available
                    local neighborStyle = nil
                    if neighbor and neighbor.id and self.entityManager then
                        local topoComp = self.entityManager:getComponent(
                            neighbor.id,
                            ComponentType.TOPOGRAPHY
                        )
                        if topoComp and topoComp.style ~= nil then
                            neighborStyle = topoComp.style
                        else
                            neighborStyle = neighbor.style
                        end
                    else
                        neighborStyle = neighbor and neighbor.style
                    end

                    if neighborStyle ~= TopographyType.INACCESSIBLE then
                        -- neighbor.position already exists as Tile.position (Vec2)
                        table.insert(tile.neighbors, neighbor)
                    end
                end
            end
        end
    end
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
--- @return Tile|nil
function MapManager:getNode(x, y)
    -- graph is graph[x][y]
    return self.graph and self.graph[x] and self.graph[x][y]
end

--- Convert a world position to grid indices.
--- @param pos Vec2
--- @return Vec2 (grid indices)
function MapManager:worldToGrid(pos)
    local x = math.floor(pos.x / constants.pixelSize) + 1
    local y = math.floor(pos.y / constants.pixelSize) + 1
    return Vec2.new(x, y)
end

--- Convert grid indices back to world coordinates (center of tile).
--- @param x integer
--- @param y integer
--- @return Vec2 world coordinate (center)
function MapManager:gridToWorld(x, y)
    local wx = (x - 1) * constants.pixelSize + constants.pixelSize / 2
    local wy = (y - 1) * constants.pixelSize + constants.pixelSize / 2
    return Vec2.new(wx, wy)
end

--- Convert grid indices back to top-left world coordinate (helper).
--- @param x integer
--- @param y integer
--- @return Vec2 world coordinate (top-left)
function MapManager:gridToWorldTopLeft(x, y)
    local wx = (x - 1) * constants.pixelSize
    local wy = (y - 1) * constants.pixelSize
    return Vec2.new(wx, wy)
end

--- @param x          integer
--- @param y          integer
--- @param newStyle   TopographyType
function MapManager:updateTileStyle(x, y, newStyle)
    local tile = self.graph[x] and self.graph[x][y]
    if not tile then
        return
    end

    local entity = self.entityManager:getComponent(tile.id, ComponentType.TOPOGRAPHY)
    if entity then
        -- Overwrite the topography component properly (Topography component expected)
        self.entityManager:addComponent(
            tile.id,
            ComponentType.TOPOGRAPHY,
            Topography.new(newStyle, TopographyMap[newStyle] or 0)
        )
    else
        -- Fallback: try adding a component using provided newStyle value
        self.entityManager:addComponent(
            tile.id,
            ComponentType.TOPOGRAPHY,
            Topography.new(newStyle, TopographyMap[newStyle] or 0)
        )
    end

    self.dirtyGraph = true
end

--- Get the style table for a tile (cached or read from its entity).
--- @param x integer
--- @param y integer
--- @return TopographyType|nil
function MapManager:getTileStyle(x, y)
    local tile = self.graph[x] and self.graph[x][y]
    if not tile then
        return nil
    end

    local topography = nil
    if tile.id and self.entityManager then
        topography = self.entityManager:getComponent(tile.id, ComponentType.TOPOGRAPHY)
    end

    -- If the component was returned directly, it may be a Topography object with a .style field.
    if topography and topography.style ~= nil then
        return topography.style
    end

    -- Fallback: if Tile stores style directly
    return tile.style
end

return MapManager
