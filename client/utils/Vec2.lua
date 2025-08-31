--- @class Vec2
--- @field x number
--- @field y number
local Vec2 = {}
Vec2.__index = Vec2

--- @param x? number Position x (default: 0)
--- @param y? number Position y (default: 0)
--- @return Vec2
function Vec2.new(x, y)
    local self = setmetatable({}, { __index = Vec2 })
    self.x = x or 0
    self.y = y or 0
    return self
end

--- Add two vectors together. Useful for:
--- - Combining position and velocity (movement)
--- - Adding forces together
--- - Offsetting positions
--- @param other Vec2
--- @return Vec2
function Vec2:add(other)
    return Vec2.new(self.x + other.x, self.y + other.y)
end

--- Subtract one vector from another. Useful for:
--- - Getting direction between two points
--- - Finding relative position
--- - Calculating distance vectors
--- @param other Vec2
--- @return Vec2
function Vec2:sub(other)
    return Vec2.new(self.x - other.x, self.y - other.y)
end

--- Multiply vector by a scalar. Useful for:
--- - Scaling velocity by delta time
--- - Applying speed multipliers
--- - Scaling forces or movement
--- @param scalar number
--- @return Vec2
function Vec2:mul(scalar)
    return Vec2.new(self.x * scalar, self.y * scalar)
end

--- Divide vector by a scalar. Useful for:
--- - Averaging positions
--- - Reducing vectors
--- - Part of normalization
--- @param scalar number
--- @return Vec2
function Vec2:div(scalar)
    if scalar == 0 then
        return Vec2.new(0, 0)
    end
    return Vec2.new(self.x / scalar, self.y / scalar)
end

--- Get the length (magnitude) of the vector. Useful for:
--- - Checking distances
--- - Testing ranges
--- - Comparing vector sizes
--- @return number
function Vec2:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

--- Get the normalized vector (length of 1). Useful for:
--- - Getting pure direction without magnitude
--- - Ensuring consistent movement speeds
--- - Creating unit vectors for calculations
--- @return Vec2
function Vec2:normalize()
    local len = self:length()
    if len > 0 then
        return self:div(len)
    end
    return self
end

--- Get dot product of two vectors. Useful for:
--- - Checking if vectors are facing same direction
--- - Testing angles between vectors
--- - Projecting one vector onto another
--- @param other Vec2
--- @return number
function Vec2:dot(other)
    return self.x * other.x + self.y * other.y
end

--- Linearly interpolate between this vector and another.
--- Creates a new vector positioned between the two.
--- Useful for smoothing movement, creating easing effects, or interpolating camera positions.
--- @param target Vec2 The target vector to interpolate towards.
--- @param amount number The interpolation factor (typically 0.0 to 1.0).
--- @return Vec2 A new Vec2 instance with the interpolated coordinates.
function Vec2:lerp(target, amount)
    local newX = self.x + (target.x - self.x) * amount
    local newY = self.y + (target.y - self.y) * amount
    return Vec2.new(newX, newY)
end

return Vec2
