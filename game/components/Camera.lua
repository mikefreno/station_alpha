local constants = require("utils.constants")
local Vec2 = require("utils.Vec2")

---@class Camera
---@field position Vec2   -- Logical world position of the camera’s centre
---@field zoom number     -- Scale factor (pure number)
---@field zoomRate number -- Speed of zooming
---@field borderPadding number  -- In logical tiles
local Camera = {}
Camera.__index = Camera

--- Constructor
function Camera.new()
  local self = setmetatable({}, Camera)

  -- Start at the map’s origin – the camera’s centre is at (0,0)
  self.position = Vec2.new(0, 0)

  self.zoom = 1 -- 1× means “1 logical tile = pixelSize pixels”
  self.zoomRate = 0.1
  self.borderPadding = 0.5 -- ½ tile (in logical units)

  return self
end

--- Move the camera by a logical offset
---@param dx number
---@param dy number
function Camera:move(dx, dy)
  self.position:mutAdd(dx, dy)

  -- Clamp to left / top borders (if you want a “no‑negative‑world‑coords” behaviour)
  if self.position.x < -self.borderPadding then
    self.position.x = -self.borderPadding
  end
  if self.position.y < -self.borderPadding then
    self.position.y = -self.borderPadding
  end
end

--- Set zoom level – keep it strictly positive
---@param z number
function Camera:setZoom(z)
  if z > 0 then
    self.zoom = z
  end
end

--- Apply camera transform (push, translate, scale)
function Camera:apply()
  love.graphics.push("all")

  -- Scale first so that the translation is already zoom‑aware.
  love.graphics.scale(self.zoom, self.zoom)

  -- Convert logical world coordinates to pixel space.
  love.graphics.translate(-self.position.x * constants.pixelSize, -self.position.y * constants.pixelSize)
end

--- Reset camera state (pop the transform)
function Camera:unapply()
  love.graphics.pop()
end

--- Handle keyboard + mouse input for camera movement + zoom
---@param dt number
function Camera:update(dt)
  local moveSpeed = 20 -- logical tiles per second – adjust as needed
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

--- Mouse‑wheel callback for zooming
---@param x number  (unused)
---@param y number  Scroll delta
function Camera:wheelmoved(x, y)
  local newZoom = math.max(0.1, self.zoom - (y * self.zoomRate))
  self:setZoom(newZoom)
end

return Camera.new()
