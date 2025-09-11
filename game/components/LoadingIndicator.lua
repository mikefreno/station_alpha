---@class Spinner
---@field angle number
---@field speed number
---@field radius number
---@field thickness number
---@field color  table
local Spinner = {}

function Spinner.new()
  local instance = setmetatable({}, { __index = Spinner })
  instance.angle = 0
  instance.speed = 2 -- Rotations per second
  instance.radius = 20
  instance.thickness = 4
  instance.color = { 1, 1, 1, 1 }
  return instance
end

function Spinner:update(dt)
  self.angle = self.angle + (dt * self.speed * math.pi * 2)
end

function Spinner:draw(x, y)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(self.angle)

  -- Set line width
  love.graphics.setLineWidth(self.thickness)

  -- Draw arc
  local segments = 32
  local startAngle = 0
  local endAngle = math.pi * 1.5 -- 3/4 of a circle

  for i = 1, segments do
    local a1 = startAngle - (i - 1) * (endAngle - startAngle) / segments
    local a2 = startAngle - i * (endAngle - startAngle) / segments
    local alpha = 1 - (i - 1) / segments

    love.graphics.setColor(1, 1, 1, alpha)
    -- Draw line segment instead of arc
    local x1 = math.cos(a1) * self.radius
    local y1 = math.sin(a1) * self.radius
    local x2 = math.cos(a2) * self.radius
    local y2 = math.sin(a2) * self.radius
    love.graphics.line(x1, y1, x2, y2)
  end

  love.graphics.pop()
end

---@class LoadingIndicator
---@field isVisible boolean
---@field spinner Spinner
local LoadingIndicator = {}
LoadingIndicator.__index = LoadingIndicator

function LoadingIndicator.new()
  local self = setmetatable({}, LoadingIndicator)
  self.isVisible = false
  self.spinner = Spinner.new()
  self.spinner.radius = 20
  self.spinner.thickness = 4
  self.spinner.color = { 1, 1, 1, 1 }
  return self
end

function LoadingIndicator:show()
  self.isVisible = true
  self.spinner.angle = 0
end

function LoadingIndicator:hide()
  self.isVisible = false
end

function LoadingIndicator:update(dt)
  if self.isVisible then
    self.spinner:update(dt)
  end
end

function LoadingIndicator:draw()
  if not self.isVisible then
    return
  end

  local screenWidth, screenHeight = love.graphics.getDimensions()
  local spinnerSize = screenWidth * 0.15 -- 15% of screen width
  local centerX = screenWidth / 2
  local centerY = screenHeight / 2

  -- Semi-transparent black overlay
  love.graphics.setColor(0, 0, 0, 0.7) -- 70% transparent black
  love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

  -- Draw spinner centered on screen
  self.spinner.radius = spinnerSize / 2
  self.spinner:draw(centerX, centerY)
end

return LoadingIndicator.new()
