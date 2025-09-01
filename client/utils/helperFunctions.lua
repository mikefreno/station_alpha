local MapCell = require("components.MapCell")

---@param entityManager EntityManager
---@param width integer
---@param height integer
---@return table
local function createLevelMap(entityManager, width, height)
	local tiles = {}
	for y = 1, height do
		for x = 1, width do
			local tileId = MapCell.new(entityManager, x, y)
			table.insert(tiles, tileId)
		end
	end
	return tiles
end

return {
	createLevelMap = createLevelMap,
}
