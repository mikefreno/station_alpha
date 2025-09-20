package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
Logger = require("logger")

-- Mock global EntityManager
EntityManager = {
  entities = {},
  components = {},
  getComponent = function(self, entityId, componentType)
    if self.components[componentType] then
      return self.components[componentType][entityId]
    end
    return nil
  end
}

-- Mock love timer
love = {
  timer = {
    getTime = function() return 10.0 end
  }
}

local TaskComponent = require("components.TaskComponent")
local Vec2 = require("utils.Vec2")

TestTaskComponent = {}

function TestTaskComponent:setUp()
  -- Reset EntityManager state
  EntityManager.entities = {}
  EntityManager.components = {}
end

function TestTaskComponent:test_create_valid_task_component()
  local target = Vec2.new(5, 3)
  local task = TaskComponent.new(target, 3, 1.5, 2.0)
  
  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.target, target)
  luaunit.assertEquals(task.priority, 3)
  luaunit.assertEquals(task.requiredDistance, 1.5)
  luaunit.assertEquals(task.estimatedDuration, 2.0)
  luaunit.assertFalse(task.isComplete)
  luaunit.assertNil(task.entityId)
end

function TestTaskComponent:test_create_with_defaults()
  local target = 42 -- Entity ID
  local task = TaskComponent.new(target, 2)
  
  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.target, 42)
  luaunit.assertEquals(task.priority, 2)
  luaunit.assertEquals(task.requiredDistance, 1.0)
  luaunit.assertEquals(task.estimatedDuration, 1.0)
end

function TestTaskComponent:test_invalid_target()
  local task = TaskComponent.new(nil, 3)
  luaunit.assertNil(task)
end

function TestTaskComponent:test_invalid_priority_too_low()
  local task = TaskComponent.new(Vec2.new(1, 1), 0)
  luaunit.assertNil(task)
end

function TestTaskComponent:test_invalid_priority_too_high()
  local task = TaskComponent.new(Vec2.new(1, 1), 7)
  luaunit.assertNil(task)
end

function TestTaskComponent:test_mark_complete()
  local task = TaskComponent.new(Vec2.new(1, 1), 3)
  luaunit.assertFalse(task.isComplete)
  
  task:markComplete()
  luaunit.assertTrue(task.isComplete)
end

function TestTaskComponent:test_get_progress_complete()
  local task = TaskComponent.new(Vec2.new(1, 1), 3)
  task:markComplete()
  
  luaunit.assertEquals(task:getProgress(), 1.0)
end

function TestTaskComponent:test_get_progress_partial()
  -- Create task first, then mock time progression
  local task = TaskComponent.new(Vec2.new(1, 1), 3, 1.0, 10.0) -- 10 second duration
  
  -- Mock time progression - simulate 5 seconds elapsed
  task.startTime = 10.0
  love.timer.getTime = function() return 15.0 end -- 5 seconds elapsed
  
  luaunit.assertEquals(task:getProgress(), 0.5) -- 50% complete
end

function TestTaskComponent:test_get_target_position_vec2()
  local target = Vec2.new(5, 3)
  local task = TaskComponent.new(target, 3)
  
  local pos = task:getTargetPosition()
  luaunit.assertNotNil(pos)
  luaunit.assertEquals(pos.x, 5)
  luaunit.assertEquals(pos.y, 3)
end

function TestTaskComponent:test_get_target_position_entity()
  -- Set up entity with position
  EntityManager.entities[42] = true
  EntityManager.components[1] = { [42] = Vec2.new(10, 8) } -- ComponentType.POSITION = 1
  
  local task = TaskComponent.new(42, 3)
  local pos = task:getTargetPosition()
  
  luaunit.assertNotNil(pos)
  luaunit.assertEquals(pos.x, 10)
  luaunit.assertEquals(pos.y, 8)
end

function TestTaskComponent:test_is_in_range_true()
  local task = TaskComponent.new(Vec2.new(5, 5), 3, 2.0)
  local entityPos = Vec2.new(4, 4) -- Distance is ~1.414, within 2.0
  
  luaunit.assertTrue(task:isInRange(entityPos))
end

function TestTaskComponent:test_is_in_range_false()
  local task = TaskComponent.new(Vec2.new(5, 5), 3, 1.0)
  local entityPos = Vec2.new(3, 3) -- Distance is ~2.828, not within 1.0
  
  luaunit.assertFalse(task:isInRange(entityPos))
end

function TestTaskComponent:test_is_valid_vec2_target()
  local task = TaskComponent.new(Vec2.new(1, 1), 3)
  luaunit.assertTrue(task:isValid())
end

function TestTaskComponent:test_is_valid_entity_target_exists()
  EntityManager.entities[42] = true
  local task = TaskComponent.new(42, 3)
  
  luaunit.assertTrue(task:isValid())
end

function TestTaskComponent:test_is_valid_entity_target_missing()
  local task = TaskComponent.new(42, 3) -- Entity 42 doesn't exist
  
  luaunit.assertFalse(task:isValid())
end

function TestTaskComponent:test_to_string()
  local task = TaskComponent.new(Vec2.new(5, 3), 4, 1.5)
  local str = task:toString()
  
  luaunit.assertStrContains(str, "Vec2(5.0,3.0)")
  luaunit.assertStrContains(str, "priority=4")
  luaunit.assertStrContains(str, "distance=1.5")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())