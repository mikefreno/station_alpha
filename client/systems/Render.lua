local ComponentType = require("utils.enums").ComponentType
local Shapes        = require("utils.enums").Shapes
local helper        = require("utils.helperFunctions")
local TILE_SIZE     = helper.TILE_SIZE      -- default 10

local RenderSystem  = {}
RenderSystem.__index = RenderSystem

function RenderSystem.new()
    return setmetatable({}, RenderSystem)
end

--- Draw every entity that has a POSITION component.
function RenderSystem:update(entityManager)
    love.graphics.clear(0.1, 0.1, 0.1)

    for _, e in ipairs(self:query(entityManager, ComponentType.POSITION)) do
        local pos   = entityManager:getComponent(e, ComponentType.POSITION)
        local tex   = entityManager:getComponent(e, ComponentType.TEXTURE)
        local shape = entityManager:getComponent(e, ComponentType.SHAPE)

        -- Colour
        local r, g, b = 1, 1, 1
        if tex and tex.color then
            r, g, b = tex.color.r, tex.color.g, tex.color.b
        end
        love.graphics.setColor(r, g, b)

        -- -------------------------------------------------------
        -- 1️⃣  Tiles / Squares that may be border‑only
        -- -------------------------------------------------------
        if shape and shape.shape == Shapes.SQUARE then
            local size  = shape.size or 10
            local half  = size / 2
            local x, y  = pos.x - half, pos.y - half
            local mode  = shape.border_only and "line" or "fill"

            -- Optional line width – you can tweak or expose as a component
            local lineWidth = shape.border_width or 1
            love.graphics.setLineWidth(lineWidth)

            love.graphics.rectangle(mode, x, y, size, size)
            goto continue        -- skip the generic “continue” label
        end

        -- -------------------------------------------------------
        -- 2️⃣  Circles (dot, etc.) – always filled unless border_only
        -- -------------------------------------------------------
        if shape and shape.shape == Shapes.CIRCLE then
            local radius = shape.size or 10
            local mode   = shape.border_only and "line" or "fill"
            local lineWidth = shape.border_width or 1
            love.graphics.setLineWidth(lineWidth)

            love.graphics.circle(mode, pos.x, pos.y, radius)
            goto continue
        end

        -- -------------------------------------------------------
        -- 3️⃣  Tiles that **only** have POSITION + TEXTURE
        -- -------------------------------------------------------
        if not shape then
            love.graphics.rectangle("fill",
                pos.x, pos.y,
                TILE_SIZE, TILE_SIZE)
            goto continue
        end

        ::continue::
    end
end

------------------------------------------------------------------
-- Helper – return all entities that contain the required types
------------------------------------------------------------------
function RenderSystem:query(entityManager, ...)
    local required = { ... }
    local result   = {}
    for e, _ in pairs(entityManager.entities) do
        local ok = true
        for _, t in ipairs(required) do
            if not entityManager.components[t] or
               not entityManager.components[t][e] then
                ok = false
                break
            end
        end
        if ok then table.insert(result, e) end
    end
    return result
end

return RenderSystem.new()
