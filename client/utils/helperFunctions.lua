local enums = require("utils.enums")
local ComponentType = enums.ComponentType
local Shapes = enums.Shapes
local TILE_SIZE = 25

---@param entityManager EntityManager
---@param width integer
---@param height integer
---@return table
local function createLevelMap(entityManager, width, height)
    local tiles = {}
    for y = 1, height do
        for x = 1, width do
            local tileId = entityManager:createEntity()
            entityManager:addComponent(tileId, ComponentType.POSITION, { x = (x - 1) * TILE_SIZE, y = (y - 1) * TILE_SIZE })
            entityManager:addComponent(tileId, ComponentType.TEXTURE, { color = { r = 0.5, g = 0.5, b = 0.5 } })
            entityManager:addComponent(tileId, ComponentType.SHAPE,
                { shape = Shapes.SQUARE, size = TILE_SIZE, border_only = true })
            table.insert(tiles, tileId)
        end
    end
    return tiles
end

return {
    createLevelMap = createLevelMap,
    TILE_SIZE = TILE_SIZE
}
