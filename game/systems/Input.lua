local ComponentType = require("game.utils.enums").ComponentType
local EntityManager = require("game.systems.EntityManager")
local PauseMenu = require("game.components.PauseMenu")
local Vec2 = require("game.utils.Vec2")
local RightClickMenu = require("game.components.RightClickMenu")

local InputSystem = {}
InputSystem.__index = InputSystem

function InputSystem.new()
  local self = setmetatable({}, InputSystem)
  return self
end

function InputSystem:update() end

function InputSystem:keypressed(key, scancode, isrepeat)
  if key == "escape" then
    if RightClickMenu.window then
      RightClickMenu:destroy()
    else
      PauseMenu:toggle()
    end
  else
  end
end

---comment
---@param x number
---@param y number
---@param button integer
---@param istouch boolean
function InputSystem:handleMousePressed(x, y, button, istouch)
  if button == 1 then
    if RightClickMenu.window and not RightClickMenu:clickWithin(x, y) then
      RightClickMenu:destroy()
    end
    if PauseMenu.window then
      return
    end
    -- Find entities at the click position that are not map tiles
    local entities = EntityManager:query(ComponentType.POSITION)
    for _, entityId in ipairs(entities) do
      local selected = EntityManager:getComponent(entityId, ComponentType.SELECTED)
      if selected == true and not RightClickMenu:clickWithin(x, y) then
        EntityManager:addComponent(entityId, ComponentType.SELECTED, false)
      end
      -- Skip map tile entities
      if EntityManager:getComponent(entityId, ComponentType.MAPTILE_TAG) == nil then
        local bounds = EntityManager:getEntityBounds(entityId)
        if bounds then
          -- Check if click position is within entity bounds
          if x >= bounds.x and x <= bounds.x + bounds.width and y >= bounds.y and y <= bounds.y + bounds.height then
            EntityManager:addComponent(entityId, ComponentType.SELECTED, true)
            break
          end
        end
      end
    end
    --if not RCM.hovered then RCM:hide() end
  elseif button == 2 then
    if RightClickMenu then
      RightClickMenu:updatePosition(x, y)
    else
      Logger:error("No RCM found")
    end
  end
end

function InputSystem:handleWheelMoved(x, y)
  if RightClickMenu.window then
  else
    Camera:wheelmoved(x, y)
  end
end

return InputSystem.new()
