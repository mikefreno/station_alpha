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
  end,
}

-- Mock love timer
love = {
  timer = {
    getTime = function()
      return 10.0
    end,
  },
}

local MovementTask = require("components.MovementTask")
local Vec2 = require("utils.Vec2")

TestMovementTask = {}

function TestMovementTask:setUp()
  -- Reset state
  EntityManager.entities = {}
  EntityManager.components = {}
end

function TestMovementTask:test_create_valid_movement_task()
  local target = Vec2.new(10, 8)
  local task = MovementTask.new(target, 0.5, 1.5)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.targetPosition.x, 10)
  luaunit.assertEquals(task.targetPosition.y, 8)
  luaunit.assertEquals(task.requiredDistance, 0.5)
  luaunit.assertEquals(task.movementSpeed, 1.5)
  luaunit.assertEquals(task.priority, 6) -- Highest priority
  luaunit.assertFalse(task.isComplete)
  luaunit.assertEquals(task.currentWaypoint, 1)
end

function TestMovementTask:test_create_with_defaults()
  local target = Vec2.new(5, 5)
  local task = MovementTask.new(target)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.requiredDistance, 0.5)
  luaunit.assertEquals(task.movementSpeed, 1.0)
end

function TestMovementTask:test_invalid_target()
  local task = MovementTask.new(nil)
  luaunit.assertNil(task)
end

function TestMovementTask:test_set_path()
  local task = MovementTask.new(Vec2.new(10, 8))
  local path = {
    Vec2.new(2, 2),
    Vec2.new(5, 5),
    Vec2.new(8, 6),
    Vec2.new(10, 8),
  }

  task:setPath(path)

  luaunit.assertEquals(#task.path, 4)
  luaunit.assertEquals(task.currentWaypoint, 1)
  luaunit.assertEquals(task.targetPosition.x, 10)
  luaunit.assertEquals(task.targetPosition.y, 8)
  luaunit.assertTrue(task.totalDistance > 0)
end

function TestMovementTask:test_set_empty_path()
  local task = MovementTask.new(Vec2.new(10, 8))
  task:setPath({})

  -- Should still have empty path and give error
  luaunit.assertEquals(#task.path, 0)
end

function TestMovementTask:test_get_current_target()
  local task = MovementTask.new(Vec2.new(10, 8))
  local path = { Vec2.new(2, 2), Vec2.new(5, 5), Vec2.new(10, 8) }
  task:setPath(path)

  local current = task:getCurrentTarget()
  luaunit.assertNotNil(current)
  luaunit.assertEquals(current.x, 2)
  luaunit.assertEquals(current.y, 2)
end

function TestMovementTask:test_advance_waypoint()
  local task = MovementTask.new(Vec2.new(10, 8))
  local path = { Vec2.new(2, 2), Vec2.new(5, 5), Vec2.new(10, 8) }
  task:setPath(path)

  luaunit.assertTrue(task:advanceWaypoint())
  luaunit.assertEquals(task.currentWaypoint, 2)

  local current = task:getCurrentTarget()
  luaunit.assertEquals(current.x, 5)
  luaunit.assertEquals(current.y, 5)

  luaunit.assertTrue(task:advanceWaypoint())
  luaunit.assertEquals(task.currentWaypoint, 3)

  luaunit.assertFalse(task:advanceWaypoint()) -- At end
  luaunit.assertEquals(task.currentWaypoint, 3)
end

function TestMovementTask:test_is_at_current_waypoint()
  local task = MovementTask.new(Vec2.new(10, 8))
  local path = { Vec2.new(2, 2), Vec2.new(5, 5), Vec2.new(10, 8) }
  task:setPath(path)

  -- Close to first waypoint
  luaunit.assertTrue(task:isAtCurrentWaypoint(Vec2.new(2.05, 2.05)))

  -- Not close to first waypoint
  luaunit.assertFalse(task:isAtCurrentWaypoint(Vec2.new(3, 3)))

  -- Advance and test second waypoint
  task:advanceWaypoint()
  luaunit.assertTrue(task:isAtCurrentWaypoint(Vec2.new(5.05, 5.05)))
  luaunit.assertFalse(task:isAtCurrentWaypoint(Vec2.new(2, 2)))
end

function TestMovementTask:test_is_at_destination()
  local task = MovementTask.new(Vec2.new(10, 8), 1.0) -- 1.0 required distance
  local path = { Vec2.new(2, 2), Vec2.new(10, 8) }
  task:setPath(path)

  -- Within required distance
  luaunit.assertTrue(task:isAtDestination(Vec2.new(10.5, 8.5)))

  -- Outside required distance
  luaunit.assertFalse(task:isAtDestination(Vec2.new(8, 6)))
end

function TestMovementTask:test_update_movement_progression()
  local task = MovementTask.new(Vec2.new(10, 8), 0.5)
  local path = { Vec2.new(0, 0), Vec2.new(5, 4), Vec2.new(10, 8) }
  task:setPath(path)

  -- At first waypoint, should advance
  luaunit.assertTrue(task:update(Vec2.new(0.05, 0.05)))
  luaunit.assertEquals(task.currentWaypoint, 2)

  -- At second waypoint, should advance
  luaunit.assertTrue(task:update(Vec2.new(5.05, 4.05)))
  luaunit.assertEquals(task.currentWaypoint, 3)

  -- At destination, should complete
  luaunit.assertFalse(task:update(Vec2.new(10.2, 8.2)))
  luaunit.assertTrue(task.isComplete)
end

function TestMovementTask:test_get_progress_no_path()
  local task = MovementTask.new(Vec2.new(10, 8))
  luaunit.assertEquals(task:getProgress(), 0.0)
end

function TestMovementTask:test_get_progress_with_position()
  local task = MovementTask.new(Vec2.new(10, 0))
  local path = { Vec2.new(0, 0), Vec2.new(5, 0), Vec2.new(10, 0) }
  task:setPath(path)

  -- Halfway to first waypoint - should be 25% complete (2.5/10)
  local progress = task:getProgress(Vec2.new(2.5, 0))
  luaunit.assertTrue(math.abs(progress - 0.25) < 0.01)

  -- At first waypoint, advance to second
  task:advanceWaypoint()
  -- Halfway to second waypoint - should be 75% complete (7.5/10)
  progress = task:getProgress(Vec2.new(7.5, 0))
  luaunit.assertTrue(math.abs(progress - 0.75) < 0.01)
end

function TestMovementTask:test_has_valid_path()
  local task = MovementTask.new(Vec2.new(10, 8))

  luaunit.assertFalse(task:hasValidPath())

  task:setPath({ Vec2.new(0, 0), Vec2.new(10, 8) })
  luaunit.assertTrue(task:hasValidPath())
end

function TestMovementTask:test_get_remaining_distance()
  local task = MovementTask.new(Vec2.new(10, 8))
  local path = { Vec2.new(0, 0), Vec2.new(10, 8) }
  task:setPath(path)

  -- From halfway point
  local remaining = task:getRemainingDistance(Vec2.new(5, 4))
  luaunit.assertTrue(math.abs(remaining - math.sqrt(25 + 16)) < 0.01) -- ~6.4
end

function TestMovementTask:test_to_string()
  local task = MovementTask.new(Vec2.new(10, 8), 0.5, 1.2)
  local path = { Vec2.new(0, 0), Vec2.new(5, 4), Vec2.new(10, 8) }
  task:setPath(path)

  local str = task:toString()
  luaunit.assertStrContains(str, "MovementTask")
  luaunit.assertStrContains(str, "Vec2(10.0,8.0)")
  luaunit.assertStrContains(str, "waypoint=1/3")
  luaunit.assertStrContains(str, "speed=1.2")
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())
