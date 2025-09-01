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
}
