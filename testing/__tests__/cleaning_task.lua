package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")
Logger = require("logger")

-- Mock love module
love = {
  timer = {
    getTime = function()
      return 10.0
    end
  }
}

local CleaningTask = require("components.CleaningTask")
local Vec2 = require("utils.Vec2")
local enums = require("utils.enums")

TestCleaningTask = {}

function TestCleaningTask:setUp()
  -- Reset love timer for consistent testing
  if love and love.timer then
    love.timer = {
      getTime = function()
        return 10.0
      end
    }
  end
end

function TestCleaningTask:test_new_valid_cleaning_task()
  local target = Vec2.new(5, 5)
  local task = CleaningTask.new(target, 2.0, enums.ToolType.BROOM, 0.5, 20.0)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.target, target)
  luaunit.assertEquals(task.priority, 1)
  luaunit.assertEquals(task.cleaningRadius, 2.0)
  luaunit.assertEquals(task.cleaningTool, enums.ToolType.BROOM)
  luaunit.assertEquals(task.cleaningRate, 0.5)
  luaunit.assertEquals(task.totalDirtiness, 20.0)
  luaunit.assertEquals(task.cleanedDirtiness, 0)
  luaunit.assertEquals(task.estimatedDuration, 40.0) -- 20.0 / 0.5
  luaunit.assertFalse(task.isComplete)
end

function TestCleaningTask:test_new_with_defaults()
  local target = Vec2.new(3, 3)
  local task = CleaningTask.new(target, 1.5, enums.ToolType.MOP)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.cleaningRadius, 1.5)
  luaunit.assertEquals(task.cleaningTool, enums.ToolType.MOP)
  luaunit.assertEquals(task.cleaningRate, 0.5) -- default rate
  luaunit.assertEquals(task.totalDirtiness, 10.0) -- default dirtiness
  luaunit.assertEquals(task.estimatedDuration, 20.0) -- 10.0 / 0.5
end

function TestCleaningTask:test_new_invalid_parameters()
  -- No target
  local task = CleaningTask.new(nil, 1.0, enums.ToolType.BROOM)
  luaunit.assertNil(task)

  -- Invalid cleaning radius
  task = CleaningTask.new(Vec2.new(1, 1), 0, enums.ToolType.BROOM)
  luaunit.assertNil(task)

  task = CleaningTask.new(Vec2.new(1, 1), -1.0, enums.ToolType.BROOM)
  luaunit.assertNil(task)

  -- Invalid cleaning tool
  task = CleaningTask.new(Vec2.new(1, 1), 1.0, 999)
  luaunit.assertNil(task)

  task = CleaningTask.new(Vec2.new(1, 1), 1.0, -1)
  luaunit.assertNil(task)

  -- Invalid cleaning rate
  task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.BROOM, 0)
  luaunit.assertNil(task)

  task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.BROOM, -0.1)
  luaunit.assertNil(task)

  -- Invalid total dirtiness
  task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.BROOM, 0.5, 0)
  luaunit.assertNil(task)

  task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.BROOM, 0.5, -5.0)
  luaunit.assertNil(task)
end

function TestCleaningTask:test_update_progress()
  local task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.MOP, 1.0, 5.0)
  luaunit.assertNotNil(task)

  -- Initial state
  luaunit.assertEquals(task.cleanedDirtiness, 0)

  -- Progress through cleaning
  local stillWorking = task:updateProgress(2.0) -- 2.0 units cleaned
  luaunit.assertTrue(stillWorking)
  luaunit.assertEquals(task.cleanedDirtiness, 2.0)
  luaunit.assertFalse(task.isComplete)

  -- Progress more
  stillWorking = task:updateProgress(2.0) -- +2.0 = 4.0 total
  luaunit.assertTrue(stillWorking)
  luaunit.assertEquals(task.cleanedDirtiness, 4.0)
  luaunit.assertFalse(task.isComplete)

  -- Complete cleaning
  stillWorking = task:updateProgress(1.5) -- +1.5 = 5.5 total (capped at 5.0)
  luaunit.assertFalse(stillWorking)
  luaunit.assertEquals(task.cleanedDirtiness, 5.0) -- capped at totalDirtiness
  luaunit.assertTrue(task.isComplete)
end

function TestCleaningTask:test_get_progress()
  local task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.SCRUBBER, 0.5, 8.0)
  luaunit.assertNotNil(task)

  -- Initial progress
  luaunit.assertEquals(task:getProgress(), 0.0)

  -- Partial progress
  task:updateProgress(4.0) -- 2.0 units cleaned out of 8.0
  luaunit.assertEquals(task:getProgress(), 0.25) -- 2.0 / 8.0

  -- More progress
  task:updateProgress(8.0) -- +4.0 = 6.0 total
  luaunit.assertEquals(task:getProgress(), 0.75) -- 6.0 / 8.0

  -- Complete progress
  task:updateProgress(4.0) -- +2.0 = 8.0 total
  luaunit.assertEquals(task:getProgress(), 1.0)
end

function TestCleaningTask:test_get_remaining_work()
  local task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.BROOM, 0.25, 10.0)
  luaunit.assertNotNil(task)

  -- Initial remaining work
  luaunit.assertEquals(task:getRemainingWork(), 40.0) -- 10.0 / 0.25

  -- After some progress
  task:updateProgress(8.0) -- 2.0 units cleaned
  luaunit.assertEquals(task:getRemainingWork(), 32.0) -- 8.0 / 0.25

  -- Completed
  task:updateProgress(32.0) -- Complete
  luaunit.assertEquals(task:getRemainingWork(), 0)
end

function TestCleaningTask:test_can_perform()
  local task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.BROOM)
  luaunit.assertNotNil(task)

  -- Valid entity
  local entity = { id = 1 }
  luaunit.assertTrue(task:canPerform(entity))

  -- Nil entity
  luaunit.assertFalse(task:canPerform(nil))
end

function TestCleaningTask:test_dirty_entity_management()
  local task = CleaningTask.new(Vec2.new(1, 1), 1.0, enums.ToolType.MOP)
  luaunit.assertNotNil(task)

  -- Initially no dirty entities
  luaunit.assertEquals(task:getDirtyEntityCount(), 0)

  -- Add dirty entities
  task:addDirtyEntity(101)
  task:addDirtyEntity(102)
  task:addDirtyEntity(103)
  luaunit.assertEquals(task:getDirtyEntityCount(), 3)

  -- Check if entities are in list
  luaunit.assertTrue(task:hasDirtyEntity(101))
  luaunit.assertTrue(task:hasDirtyEntity(102))
  luaunit.assertTrue(task:hasDirtyEntity(103))
  luaunit.assertFalse(task:hasDirtyEntity(999))

  -- Remove an entity
  local removed = task:removeDirtyEntity(102)
  luaunit.assertTrue(removed)
  luaunit.assertEquals(task:getDirtyEntityCount(), 2)
  luaunit.assertFalse(task:hasDirtyEntity(102))

  -- Try to remove non-existent entity
  removed = task:removeDirtyEntity(999)
  luaunit.assertFalse(removed)
  luaunit.assertEquals(task:getDirtyEntityCount(), 2)

  -- Add invalid entity (should be ignored)
  task:addDirtyEntity(nil)
  task:addDirtyEntity(0)
  task:addDirtyEntity(-1)
  luaunit.assertEquals(task:getDirtyEntityCount(), 2) -- unchanged
end

function TestCleaningTask:test_getters()
  local task = CleaningTask.new(Vec2.new(1, 1), 3.5, enums.ToolType.SCRUBBER, 0.8, 15.0)
  luaunit.assertNotNil(task)

  luaunit.assertEquals(task:getCleaningRadius(), 3.5)
  luaunit.assertEquals(task:getRequiredTool(), enums.ToolType.SCRUBBER)
  luaunit.assertEquals(task:getCleaningRate(), 0.8)
  luaunit.assertEquals(task:getRemainingDirtiness(), 15.0)

  -- After some cleaning
  task:updateProgress(5.0) -- 4.0 units cleaned
  luaunit.assertEquals(task:getRemainingDirtiness(), 11.0) -- 15.0 - 4.0
end

function TestCleaningTask:test_to_string()
  local task = CleaningTask.new(Vec2.new(5, 8), 2.5, enums.ToolType.MOP, 0.2, 12.0)
  luaunit.assertNotNil(task)

  -- Add some dirty entities and progress
  task:addDirtyEntity(201)
  task:addDirtyEntity(202)
  task:updateProgress(10.0) -- 2.0 units cleaned

  local str = task:toString()
  luaunit.assertStrContains(str, "CleaningTask")
  luaunit.assertStrContains(str, string.format("tool=%d", enums.ToolType.MOP))
  luaunit.assertStrContains(str, "radius=2.5")
  luaunit.assertStrContains(str, "cleaned=2.0/12.0")
  luaunit.assertStrContains(str, "entities=2")
  luaunit.assertStrContains(str, "complete=false")
end

function TestCleaningTask:test_edge_cases()
  -- Test with very small numbers
  local task = CleaningTask.new(Vec2.new(1, 1), 0.1, enums.ToolType.BROOM, 0.01, 0.1)
  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.estimatedDuration, 10.0) -- 0.1 / 0.01

  -- Test progress with very small delta
  task:updateProgress(0.001) -- 0.00001 units cleaned
  luaunit.assertTrue(task:getProgress() > 0)
  luaunit.assertTrue(task:getProgress() < 0.001)
end

-- Run tests
os.exit(luaunit.LuaUnit.run())