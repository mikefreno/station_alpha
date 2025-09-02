local TILE_SIZE = require("utils.constants").TILE_SIZE
local Vec2 = require("utils.Vec2")

---@class Camera
---@field position Vec2
---@field zoom number
---@field borderPadding number
local Camera = {}
Camera.__index = Camera

function Camera.new()
  local self = setmetatable({}, Camera)
  self.position = Vec2.new()
  self.zoom = 1   -- Initial zoom level
  self.borderPadding = TILE_SIZE / 2
  return self
end

--- Moves the camera by a given amount in x and y direction.
---@param dx number -- Amount to move along the x-axis
---@param dy number -- Amount to move along the y-axis
function Camera:move(dx, dy)
  self.position.new
end

--- Sets the zoom level of the camera.
---@param z number -- New zoom level
function Camera:setZoom(z)
  if z > 0 then
    self.zoom = z
  end
end

--- Applies the camera transformation to love.graphics
function Camera:apply()
  love.graphics.push("all")
  love.graphics.translate(-self.x, -self.y)
  love.graphics.scale(self.zoom, self.zoom)
end

--- Resets the camera transformation after rendering
function Camera:unapply()
  love.graphics.pop()
end

--- Handles input for camera movement and zoom.
---@param dt number -- Delta time since last frame
function Camera:update(dt)
  local speed = 300   -- Movement speed of the camera

  if love.keyboard.isDown("w") then
    self:move(0, -speed * dt)
  end
  if love.keyboard.isDown("s") then
    self:move(0, speed * dt)
  end
  if love.keyboard.isDown("a") then
    self:move(-speed * dt, 0)
  end
  if love.keyboard.isDown("d") then
    self:move(speed * dt, 0)
  end

  if (self.x < 0) then
    self.x = 0
  end
  if (self.y < 0) then
    self.y = 0
  end
end

function Camera:wheelmoved(x, y)
  local newZoom = math.max(1, self.zoom - (y * 0.1))   -- Adjust the factor as needed
  self:setZoom(newZoom)
end

return Camera.new()
