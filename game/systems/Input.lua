local ComponentType = require("utils.enums").ComponentType

local InputSystem = {}
InputSystem.__index = InputSystem

function InputSystem.new()
    local self = setmetatable({}, InputSystem)
    return self
end

---@param entityManager EntityManager
function InputSystem:update(entityManager) end

return InputSystem.new()
