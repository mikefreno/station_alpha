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
--- @field graph         table<number, table<number, Tile>>
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
    self.graph = {} -- will hold the A* graph
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
    elseif val < 0.99 then
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
    self.entityManager:addComponent(
        tileId,
        ComponentType.MAPTILETAG,
        Vec2.new(xIndex, yIndex)
    )
    return tileId
end

function MapManager:createLevelMap()
    local tiles = {}
    for y = 1, self.height do
        tiles[y] = {}
        for x = 1, self.width do
            local tileId = self:createCell(x, y)
            local tile = Tile.new(x, y, tileId)
            tiles[y][x] = tile
        end
    end
    self.graph = tiles -- Now it's a 2D grid of Tiles
    self:buildGraph()
end

function MapManager:buildGraph()
    local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.graph[y][x]
            tile.neighbors = {}
            for _, d in ipairs(dirs) do
                local nx, ny = x + d[1], y + d[2]
                if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
                    local neighbor = self.graph[ny][nx]
                    if neighbor.style ~= TopographyType.INACCESSIBLE then
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
    return self.graph and self.graph[x] and self.graph[x][y]
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

--- @param x          integer
--- @param y          integer
--- @param newStyle   TopographyType
function MapManager:updateTileStyle(x, y, newStyle)
    local tile = self.graph[x] and self.graph[x][y]
    if not tile then
        return
    end

    local entity = self.entityManager:getComponent(tile.id, ComponentType.TOPOGRAPHY)
    self.entityManager:addComponent(entity, ComponentType.TOPOGRAPHY, newStyle)

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

    local topography = self.entityManager:getComponent(tile.id, ComponentType.TOPOGRAPHY)

    return topography
end

return MapManager
