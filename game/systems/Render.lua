local ComponentType = require("utils.enums").ComponentType
local ShapeType = require("utils.enums").ShapeType
local constants = require("utils.constants")

local RenderSystem = {}
RenderSystem.__index = RenderSystem

function RenderSystem.new()
	return setmetatable({}, RenderSystem)
end

--- Draw every entity that has a POSITION component.
function RenderSystem:update(entityManager)
	love.graphics.clear(0.1, 0.1, 0.1)

	love.graphics.push()

	for _, e in ipairs(self:query(entityManager, ComponentType.POSITION)) do
		local pos = entityManager:getComponent(e, ComponentType.POSITION)
		local tex = entityManager:getComponent(e, ComponentType.TEXTURE)
		local shape = entityManager:getComponent(e, ComponentType.SHAPE)
		local mapTile = entityManager:getComponent(e, ComponentType.MAPTILETAG)

		local r, g, b = 1, 1, 1
		if tex and tex.color then
			r, g, b = tex.color.r, tex.color.g, tex.color.b
		end
		love.graphics.setColor(r, g, b)

		if shape and shape.shape == ShapeType.SQUARE then
			local size = shape.size or 10
			love.graphics.rectangle(shape.border_only and "line" or "fill", pos.x, pos.y, size, size)
			if mapTile then
				local centerX = pos.x + constants.pixelSize / 2
				local centerY = pos.y + constants.pixelSize / 2
				love.graphics.setColor(1, 1, 1)
				love.graphics.print(mapTile.x .. "," .. mapTile.y, centerX, centerY)
			end
			goto continue
		end

		if shape and shape.shape == ShapeType.CIRCLE then
			love.graphics.circle(
				shape.border_only and "line" or "fill",
				pos.x - constants.pixelSize / 2,
				pos.y - constants.pixelSize / 2,
				shape.size or 10
			)
			goto continue
		end

		if not shape then
			love.graphics.rectangle("fill", pos.x, pos.y, 1, 1) -- 1 tile = 1 logical unit
			goto continue
		end

		::continue::
	end

	love.graphics.pop() -- restore original transform
end

function RenderSystem:query(entityManager, ...)
	local required = { ... }
	local result = {}
	for e, _ in pairs(entityManager.entities) do
		local ok = true
		for _, t in ipairs(required) do
			if not entityManager.components[t] or not entityManager.components[t][e] then
				ok = false
				break
			end
		end
		if ok then
			table.insert(result, e)
		end
	end
	return result
end

return RenderSystem.new()
