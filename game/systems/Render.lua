local enums = require("game.utils.enums")
local ComponentType = enums.ComponentType
local ShapeType = enums.ShapeType
local constants = require("game.utils.constants")

---@class RenderSystem
---@field renderBorderPadding integer
local RenderSystem = {}
RenderSystem.__index = RenderSystem

function RenderSystem.new()
    return setmetatable({
        renderBorderPadding = 2, -- tiles
    }, RenderSystem)
end

--- Draw every entity that has a POSITION component.
--- This function sorts entities to ensure map tiles are rendered at a lower z-index than other elements.
---@param bounds { x: number, y: number, width:number, height:number }
function RenderSystem:update(bounds)
    love.graphics.clear(0.54, 0.32, 0.16)

    love.graphics.push()

    -- Get all entities with POSITION component
    local entities = self:query(ComponentType.POSITION)

    -- Sort entities so that map tiles are rendered first (lower z-index)
    table.sort(entities, function(a, b)
        local aIsMapTile = EntityManager:getComponent(a, ComponentType.MAPTILETAG) ~= nil
        local bIsMapTile = EntityManager:getComponent(b, ComponentType.MAPTILETAG) ~= nil

        -- Map tiles go first (lower z-index)
        if aIsMapTile and not bIsMapTile then return true end
        if not aIsMapTile and bIsMapTile then return false end

        -- For non-map-tile entities, maintain original order
        return a < b
    end)

    for _, e in ipairs(entities) do
        --NOTE: The rightclickmenu can be rendered anywhere... therefore we dont want to do any kind of culling to affect it, it should also remain static to its position
        if e == 1 then
            if RCM then RCM:render() end
        end
        local pos = EntityManager:getComponent(e, ComponentType.POSITION)

        if
            pos.x < bounds.x - self.renderBorderPadding
            or pos.x > bounds.x + bounds.width + self.renderBorderPadding
            or pos.y < bounds.y - self.renderBorderPadding
            or pos.y > bounds.y + bounds.height + self.renderBorderPadding
        then
            goto continue
        end

        local tex = EntityManager:getComponent(e, ComponentType.TEXTURE)
        local shape = EntityManager:getComponent(e, ComponentType.SHAPE)
        local mapTile = EntityManager:getComponent(e, ComponentType.MAPTILETAG)
        local selected = EntityManager:getComponent(e, ComponentType.SELECTED)

        local r, g, b = 1, 1, 1
        if tex and tex.color then
            r, g, b = tex.color.r, tex.color.g, tex.color.b
        end
        love.graphics.setColor(r, g, b)

        -- Convert logical tile coords to pixels for rendering
        local px = pos.x * constants.pixelSize
        local py = pos.y * constants.pixelSize

        if shape and shape.shape == ShapeType.SQUARE then
            local size = shape.size * constants.pixelSize or constants.pixelSize
            love.graphics.rectangle(shape.border_only and "line" or "fill", px, py, size, size)
            if mapTile then
                local centerX = px + constants.pixelSize / 3
                local centerY = py + constants.pixelSize / 3
                love.graphics.setColor(1, 1, 1)
                if Logger.visible then love.graphics.print(mapTile.x .. "," .. mapTile.y, centerX, centerY, 0, 0.5) end
            end
        end

        if shape and shape.shape == ShapeType.CIRCLE then
            love.graphics.circle(
                shape.border_only and "line" or "fill",
                px + constants.pixelSize / 2,
                py + constants.pixelSize / 2,
                shape.size * constants.pixelSize / 2
            )
        end

        if selected == true then
            love.graphics.setLineStyle("rough")
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle(
                "line",
                px + constants.pixelSize / 8,
                py + constants.pixelSize / 8,
                shape.size * constants.pixelSize,
                shape.size * constants.pixelSize
            )
            love.graphics.setLineStyle("rough")
        end

        ::continue::
    end
    love.graphics.pop()
end

function RenderSystem:query(...)
    local required = { ... }
    local result = {}
    for e, _ in pairs(EntityManager.entities) do
        local ok = true
        for _, t in ipairs(required) do
            if not EntityManager.components[t] or not EntityManager.components[t][e] then
                ok = false
                break
            end
        end
        if ok then table.insert(result, e) end
    end
    return result
end

return RenderSystem.new()
