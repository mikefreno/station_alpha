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

local MiningTask = require("components.MiningTask")
local Vec2 = require("utils.Vec2")
local enums = require("utils.enums")

TestMiningTask = {}

function TestMiningTask:setUp()
  -- Reset love timer for consistent testing
  if love and love.timer then
    love.timer = {
      getTime = function()
        return 10.0
      end
    }
  end
end

function TestMiningTask:test_new_valid_mining_task()
  local target = Vec2.new(5, 5)
  local task = MiningTask.new(target, 5, enums.ToolType.PICKAXE, enums.ResourceType.STONE)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.target, target)
  luaunit.assertEquals(task.priority, 3)
  luaunit.assertEquals(task.swingsRemaining, 5)
  luaunit.assertEquals(task.totalSwings, 5)
  luaunit.assertEquals(task.toolRequired, enums.ToolType.PICKAXE)
  luaunit.assertEquals(task.yieldType, enums.ResourceType.STONE)
  luaunit.assertEquals(task.swingDuration, 1.0)
  luaunit.assertEquals(task.swingTimer, 0)
  luaunit.assertFalse(task.isComplete)
end

function TestMiningTask:test_new_with_custom_swing_duration()
  local target = Vec2.new(3, 3)
  local task = MiningTask.new(target, 3, enums.ToolType.PICKAXE, enums.ResourceType.IRON_ORE, 2.0)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.swingDuration, 2.0)
  luaunit.assertEquals(task.estimatedDuration, 6.0) -- 3 swings * 2.0 seconds
end

function TestMiningTask:test_new_invalid_parameters()
  -- No target
  local task = MiningTask.new(nil, 5, enums.ToolType.PICKAXE, enums.ResourceType.STONE)
  luaunit.assertNil(task)

  -- Invalid swings
  task = MiningTask.new(Vec2.new(1, 1), 0, enums.ToolType.PICKAXE, enums.ResourceType.STONE)
  luaunit.assertNil(task)

  -- Invalid tool type
  task = MiningTask.new(Vec2.new(1, 1), 5, 999, enums.ResourceType.STONE)
  luaunit.assertNil(task)

  -- Invalid resource type
  task = MiningTask.new(Vec2.new(1, 1), 5, enums.ToolType.PICKAXE, 999)
  luaunit.assertNil(task)
end

function TestMiningTask:test_update_progress_timing()
  local task = MiningTask.new(Vec2.new(1, 1), 3, enums.ToolType.PICKAXE, enums.ResourceType.STONE, 1.0)
  luaunit.assertNotNil(task)

  -- Start first swing
  task:startSwing()
  luaunit.assertEquals(task.swingTimer, 1.0)
  luaunit.assertTrue(task:isSwinging())

  -- Progress through swing
  local stillWorking = task:updateProgress(0.5)
  luaunit.assertTrue(stillWorking)
  luaunit.assertEquals(task.swingTimer, 0.5)
  luaunit.assertEquals(task.swingsRemaining, 3)

  -- Complete first swing
  stillWorking = task:updateProgress(0.5)
  luaunit.assertTrue(stillWorking)
  luaunit.assertEquals(task.swingsRemaining, 2)
  luaunit.assertEquals(task.swingTimer, 0)
end

function TestMiningTask:test_complete_mining()
  local task = MiningTask.new(Vec2.new(1, 1), 2, enums.ToolType.PICKAXE, enums.ResourceType.STONE, 0.5)
  luaunit.assertNotNil(task)

  -- Complete all swings
  task:startSwing()
  task:updateProgress(0.5) -- Complete swing 1
  task:startSwing()
  task:updateProgress(0.5) -- Complete swing 2

  luaunit.assertTrue(task.isComplete)
  luaunit.assertEquals(task.swingsRemaining, 0)
end

function TestMiningTask:test_get_progress()
  local task = MiningTask.new(Vec2.new(1, 1), 4, enums.ToolType.PICKAXE, enums.ResourceType.STONE, 1.0)
  luaunit.assertNotNil(task)

  -- Initial progress
  luaunit.assertEquals(task:getProgress(), 0.0)

  -- Start first swing
  task:startSwing()
  task:updateProgress(0.5) -- Half way through first swing
  local progress = task:getProgress()
  luaunit.assertTrue(math.abs(progress - 0.125) < 0.01) -- 0.5/4 swings

  -- Complete first swing
  task:updateProgress(0.5)
  progress = task:getProgress()
  luaunit.assertTrue(math.abs(progress - 0.25) < 0.01) -- 1/4 swings

  -- Complete all swings
  task:startSwing()
  task:updateProgress(1.0)
  task:startSwing()
  task:updateProgress(1.0)
  task:startSwing()
  task:updateProgress(1.0)

  luaunit.assertEquals(task:getProgress(), 1.0)
end

function TestMiningTask:test_can_perform()
  local task = MiningTask.new(Vec2.new(1, 1), 3, enums.ToolType.PICKAXE, enums.ResourceType.STONE)
  luaunit.assertNotNil(task)

  -- Valid entity
  local entity = { id = 1 }
  luaunit.assertTrue(task:canPerform(entity))

  -- Nil entity
  luaunit.assertFalse(task:canPerform(nil))
end

function TestMiningTask:test_remaining_work()
  local task = MiningTask.new(Vec2.new(1, 1), 3, enums.ToolType.PICKAXE, enums.ResourceType.STONE, 2.0)
  luaunit.assertNotNil(task)

  -- Initial remaining work
  luaunit.assertEquals(task:getRemainingWork(), 0) -- No swing started

  -- Start swing
  task:startSwing()
  luaunit.assertEquals(task:getRemainingWork(), 6.0) -- 2*3 + 0

  -- Progress through swing
  task:updateProgress(0.5)
  luaunit.assertEquals(task:getRemainingWork(), 5.5) -- 2*2 + 1.5

  -- Complete task
  task:startSwing()
  task:updateProgress(2.0)
  task:startSwing()
  task:updateProgress(2.0)
  task:startSwing()
  task:updateProgress(2.0)

  luaunit.assertEquals(task:getRemainingWork(), 0)
end

function TestMiningTask:test_swing_management()
  local task = MiningTask.new(Vec2.new(1, 1), 2, enums.ToolType.PICKAXE, enums.ResourceType.STONE, 1.0)
  luaunit.assertNotNil(task)

  -- Not swinging initially
  luaunit.assertFalse(task:isSwinging())

  -- Start swing
  task:startSwing()
  luaunit.assertTrue(task:isSwinging())
  luaunit.assertEquals(task.swingTimer, 1.0)

  -- Can't start another swing while one is in progress
  task:startSwing()
  luaunit.assertEquals(task.swingTimer, 1.0) -- Unchanged

  -- Complete swing
  task:updateProgress(1.0)
  luaunit.assertFalse(task:isSwinging())
end

function TestMiningTask:test_getters()
  local task = MiningTask.new(Vec2.new(1, 1), 3, enums.ToolType.HAMMER, enums.ResourceType.GOLD_ORE)
  luaunit.assertNotNil(task)

  luaunit.assertEquals(task:getRequiredTool(), enums.ToolType.HAMMER)
  luaunit.assertEquals(task:getYieldType(), enums.ResourceType.GOLD_ORE)
end

function TestMiningTask:test_to_string()
  local task = MiningTask.new(Vec2.new(5, 8), 3, enums.ToolType.PICKAXE, enums.ResourceType.STONE, 1.5)
  luaunit.assertNotNil(task)

  local str = task:toString()
  luaunit.assertStrContains(str, "MiningTask")
  luaunit.assertStrContains(str, "swings=0/3")
  luaunit.assertStrContains(str, "complete=false")
end

-- Run tests
os.exit(luaunit.LuaUnit.run())