local constants = require("game.utils.constants")
local enums = require("game.utils.enums")
local ComponentType = enums.ComponentType
local Vec2 = require("game.utils.Vec2")
local PauseMenu = require("game.components.PauseMenu")
local BottomBar = require("game.components.BottomBar")
local EventBus = require("game.systems.EventBus")

local MAP_W, MAP_H = constants.MAP_W, constants.MAP_H

---@class Camera
---@field position Vec2  -- Top‑Left of the viewport (logical coords)
---@field baseSpeed number
---@field zoom number     -- Scale factor (pure number)
---@field zoomRate number -- Speed of zooming (relative change per wheel tick)
---@field panningBorder number -- How close to the edge panning starts (0=disabled)
---@field panningZoneBuffer number -- How long before panning starts (0=start immediately)
---@field selectedEntity integer? -- Entity to track movement of
local Camera = {}
Camera.__index = Camera

local defaultPanningZoneBuffer = 0.2

--- Constructor
function Camera.new()
  local self = setmetatable({}, Camera)

  self.position = Vec2.new(1, 1)

  self.selectedEntity = nil
  self.baseSpeed = 10
  self.zoom = 1
  self.zoomRate = 0.15 -- a bit higher so you see the effect
  self.panningBorder = 0.10
  self.panningZoneBuffer = defaultPanningZoneBuffer

  -- Listen for entity selection events
  EventBus:on("entity_selected", function(data)
    if data and data.position then
      self:centerOn(data.position)
    end
  end)

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
  if PauseMenu.visible then
    return
  end
  local startPos = self.position
  local speed = self.baseSpeed / self.zoom * dt

  -- keyboard
  local keypanning = false
  if love.keyboard.isDown("w") then
    self:move(0, -speed)
    keypanning = true
  end
  if love.keyboard.isDown("s") then
    self:move(0, speed)
    keypanning = true
  end
  if love.keyboard.isDown("a") then
    self:move(-speed, 0)
    keypanning = true
  end
  if love.keyboard.isDown("d") then
    self:move(speed, 0)
    keypanning = true
  end

  -- mouse position
  local function speedClamp(x, min, max)
    return math.max(min, math.min(x, max))
  end

  local function speedFactor(pos, border)
    local dist
    if pos < border then
      dist = border - pos
    elseif pos > 1 - border then
      dist = pos - (1 - border)
    else
      dist = 0
    end
    local t = dist / border
    local factor = 0.25 + t * (3 - 2 * t) -- Fixed: was "_t_" instead of "*"
    return speedClamp(factor, 0.5, 2)
  end

  local mx, my = love.mouse.getPosition()
  local width, height = love.window.getMode()

  -- Check if BottomBar is minimized (invisible)
  local bottomBarVisible = not BottomBar.minimized
  local bottomBarHeight = BottomBar.window.height
  local offsetHeight = height - (bottomBarVisible and bottomBarHeight or 0)

  -- Check if mouse is over bottom bar
  if my > offsetHeight then
    return
  end

  local notOverVerticalPad = false

  if my / height < self.panningBorder then
    if self.panningZoneBuffer - dt > 0 then
      self.panningZoneBuffer = self.panningZoneBuffer - dt
      return
    end
    self:move(0, -speed * speedFactor(my / height, self.panningBorder))
  elseif my > (1 - self.panningBorder) * offsetHeight then
    if self.panningZoneBuffer - dt > 0 then
      self.panningZoneBuffer = self.panningZoneBuffer - dt
      return
    end
    self:move(0, speed * speedFactor(my / offsetHeight, self.panningBorder))
  else
    notOverVerticalPad = true
  end

  -- Horizontal panning
  if mx < self.panningBorder * width then
    if self.panningZoneBuffer - dt > 0 then
      self.panningZoneBuffer = self.panningZoneBuffer - dt
      goto handleselected
    end
    self:move(-speed * speedFactor(mx / width, self.panningBorder), 0)
  elseif mx > (1 - self.panningBorder) * width then
    if self.panningZoneBuffer - dt > 0 then
      self.panningZoneBuffer = self.panningZoneBuffer - dt
      goto handleselected
    end
    self:move(speed * speedFactor(mx / width, self.panningBorder), 0)
  else
    if notOverVerticalPad then
      --reset timer
      self.panningZoneBuffer = defaultPanningZoneBuffer
      goto handleselected
    end
  end

  ::handleselected::
  local selected = EntityManager:getComponent(self.selectedEntity, ComponentType.SELECTED)
  if not selected or keypanning then
    self.selectedEntity = nil
  end
  -- only track if have not moved manually
  if startPos:equals(self.position) and self.selectedEntity then
    Logger:debug(self.position)
    Logger:debug(startPos)
    local entityPos = EntityManager:getComponent(self.selectedEntity, ComponentType.POSITION)
    self:centerOn(entityPos)
  else
    self.selectedEntity = nil -- once moved manually, snap off
  end
end

--- Mouse‑wheel callback for zooming – exponential scaling
---@param y number  Scroll delta
function Camera:wheelmoved(_, y)
  if y == 0 then
    return
  end
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
  local maxY = MAP_H
    + pad
    + 1
    - logicalH
    + ((not BottomBar.minimized and BottomBar.window.height / (constants.pixelSize * self.zoom)) or 0)

  -- Clamp the camera’s logical top‑left corner
  self.position.x = math.max(minX, math.min(maxX, self.position.x))
  self.position.y = math.max(minY, math.min(maxY, self.position.y))
end

---@param point Vec2
function Camera:centerOn(point)
  local bounds = self:getVisibleBounds()
  self.position.x = point.x - bounds.width / 2
  self.position.y = point.y - bounds.height / 2
  self:clampPosition()
end

function Camera:getVisibleBounds()
  local w = love.graphics.getWidth() / (constants.pixelSize * self.zoom)
  local h = love.graphics.getHeight() / (constants.pixelSize * self.zoom)

  return { x = self.position.x, y = self.position.y, width = w, height = h }
end

return Camera
