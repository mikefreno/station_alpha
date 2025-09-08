local constants = require("utils.constants")
local Vec2 = require("utils.Vec2")

local MAP_W, MAP_H = constants.MAP_W, constants.MAP_H

---@class Camera
---@field position Vec2  -- Top‑Left of the viewport (logical coords)
---@field zoom number     -- Scale factor (pure number)
---@field zoomRate number -- Speed of zooming (relative change per wheel tick)
local Camera = {}
Camera.__index = Camera

--- Constructor
function Camera.new()
    local self = setmetatable({}, Camera)

    self.position = Vec2.new(1, 1)

    self.zoom = 1
    self.zoomRate = 0.15 -- a bit higher so you see the effect

    return self
end

--- Move the camera by a logical offset
---@param dx number
---@param dy number
function Camera:move(dx, dy)
    self.position:mutAdd(dx, dy)

    self:clampPosition()
end

--- Set zoom level – keep it strictly positive
---@param z number
function Camera:setZoom(z)
    if z > 0 then
        self.zoom = math.max(0.75, math.min(3, z))
    end
    self:clampPosition()
end

--- Apply camera transform (push, translate, scale)
function Camera:apply()
    love.graphics.push("all")
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.translate(-self.position.x * constants.pixelSize, -self.position.y * constants.pixelSize)
end

--- Reset camera state (pop the transform)
function Camera:unapply()
    love.graphics.pop()
end

--- Handle keyboard + mouse input for camera movement + zoom
---@param dt number
function Camera:update(dt)
    local moveSpeed = 10
    local speed = moveSpeed * dt

    if love.keyboard.isDown("w") then
        self:move(0, -speed)
    end
    if love.keyboard.isDown("s") then
        self:move(0, speed)
    end
    if love.keyboard.isDown("a") then
        self:move(-speed, 0)
    end
    if love.keyboard.isDown("d") then
        self:move(speed, 0)
    end
end

--- Mouse‑wheel callback for zooming – exponential scaling
---@param x number  (unused)
---@param y number  Scroll delta
function Camera:wheelmoved(x, y)
    local mx, my = love.mouse.getPosition() -- pixel coords
    local wX, wY = -- logical coords
        (mx / (constants.pixelSize * self.zoom)) + self.position.x,
        (my / (constants.pixelSize * self.zoom)) + self.position.y

    local oldZoom = self.zoom
    local newZoom = oldZoom * (1 + (y > 0 and 0.1 or -0.1))
    newZoom = math.max(0.75, math.min(3, newZoom)) -- bounds
    self.zoom = newZoom

    self.position.x = wX - (mx / (constants.pixelSize * self.zoom))
    self.position.y = wY - (my / (constants.pixelSize * self.zoom))

    self:clampPosition()
end

function Camera:clampPosition()
    local logicalW = love.graphics.getWidth() / (constants.pixelSize * self.zoom)
    local logicalH = love.graphics.getHeight() / (constants.pixelSize * self.zoom)

    -- Padding: half a tile beyond each edge
    local pad = 0.5

    local minX = 1 - pad
    local minY = 1 - pad
    local maxX = MAP_W + pad + 1 - logicalW
    local maxY = MAP_H + pad + 1 - logicalH

    -- Clamp the camera’s logical top‑left corner
    self.position.x = math.max(minX, math.min(maxX, self.position.x))
    self.position.y = math.max(minY, math.min(maxY, self.position.y))
end

function Camera:getVisibleBounds()
    local w = love.graphics.getWidth() / (constants.pixelSize * self.zoom)
    local h = love.graphics.getHeight() / (constants.pixelSize * self.zoom)

    return { x = self.position.x, y = self.position.y, width = w, height = h }
end

return Camera
