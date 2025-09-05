---@class Persistence
---@field game_saves {}
---@field user_configuration {}
local Persistence = {}
Persistence.__index = Persistence

function Persistence.new()
    local self = setmetatable({}, Persistence)
    self.game_saves = {}
    self.user_configuration = {}
    return self
end

---comment
---@param name string --user specified name for the save
---@param entityManager EntityManager
function Persistence:createGameSave(name, entityManager) end

function Persistence:loadGameSaves() end
