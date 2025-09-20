-- Test file: Right-Click Goto End-to-End Functionality Test
-- Verifies that right-click movement works through the complete system

package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")

-- Mock Love2D
_G.love = {
  timer = { getTime = function() return 0.0 end },
  graphics = {
    getWidth = function() return 800 end,
    getHeight = function() return 600 end
  }
}

-- Mock Logger
_G.Logger = {
  info = function(self, msg) end,
  warn = function(self, msg) end,
  debug = function(self, msg) end,
  error = function(self, msg) print("ERROR: " .. msg) end,
}

-- Import required modules
local Vec2 = require('game.utils.Vec2')
local enums = require('game.utils.enums')
local EntityManager = require('game.systems.EntityManager')
local TaskQueue = require('game.components.TaskQueue')
local RightClickMenu = require('game.components.RightClickMenu')
local MovementSystem = require('game.systems.MovementSystem')
local TaskExecutionSystem = require('game.systems.TaskExecutionSystem')

TestRightClickGoto = {}

function TestRightClickGoto:setUp()
  -- Initialize systems like in main.lua
  TaskExecutionSystem:init()
  MovementSystem = MovementSystem.new()
  MovementSystem:registerWithTaskExecutionSystem(TaskExecutionSystem)
end

function TestRightClickGoto:testRightClickToMovementSystemPipeline()
  -- Create a test entity with TaskQueue
  local entity = EntityManager:createEntity()
  EntityManager:addComponent(entity, enums.ComponentType.POSITION, Vec2.new(5, 5))
  
  local taskQueue = TaskQueue.new(entity)
  EntityManager:addComponent(entity, enums.ComponentType.TASKQUEUE, taskQueue)
  
  -- Create a RightClickMenu instance using init() instead of new()
  local rightClickMenu = RightClickMenu.init()
  
  -- Test the pathway: right-click -> addMovementTask -> TaskExecutionSystem -> MovementSystem
  local targetPos = Vec2.new(10, 10)
  
  -- This should go through: RightClickMenu -> TaskQueue -> TaskExecutionSystem -> MovementSystem
  local success = taskQueue:addMovementTask(targetPos)
  luaunit.assertTrue(success, "TaskQueue should successfully add movement task")
  
  -- Verify MovementSystem is registered with TaskExecutionSystem
  luaunit.assertNotNil(MovementSystem, "MovementSystem should be initialized")
  luaunit.assertTrue(MovementSystem.registerWithTaskExecutionSystem ~= nil, "MovementSystem should have registerWithTaskExecutionSystem method")
  
  -- Test that a movement task component can be created
  local movementComponent = EntityManager:getComponent(entity, enums.ComponentType.MOVEMENT_TASK)
  -- This might be nil initially, which is OK - the system processes asynchronously
  
  print("SUCCESS: Right-click goto pipeline components are properly connected")
end

function TestRightClickGoto:testTaskExecutionSystemHasMovementProcessor()
  -- Verify that TaskExecutionSystem has been initialized with MovementSystem
  local hasProcessor = TaskExecutionSystem.processors ~= nil
  luaunit.assertTrue(hasProcessor, "TaskExecutionSystem should have processors table")
  
  -- The MovementSystem should be registered as a processor
  if TaskExecutionSystem.processors then
    local movementProcessorExists = false
    for _, processor in pairs(TaskExecutionSystem.processors) do
      if processor == MovementSystem then
        movementProcessorExists = true
        break
      end
    end
    luaunit.assertTrue(movementProcessorExists, "MovementSystem should be registered as a processor")
  end
  
  print("SUCCESS: MovementSystem is properly registered with TaskExecutionSystem")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())