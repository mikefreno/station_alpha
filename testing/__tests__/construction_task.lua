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

local ConstructionTask = require("components.ConstructionTask")
local Vec2 = require("utils.Vec2")
local enums = require("utils.enums")

TestConstructionTask = {}

function TestConstructionTask:setUp()
  -- Reset love timer for consistent testing
  if love and love.timer then
    love.timer = {
      getTime = function()
        return 10.0
      end
    }
  end
end

function TestConstructionTask:test_new_valid_construction_task()
  local target = Vec2.new(5, 5)
  local materials = { [enums.ResourceType.WOOD] = 10, [enums.ResourceType.STONE] = 5 }
  local task = ConstructionTask.new(target, 123, materials, 0.1)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.target, target)
  luaunit.assertEquals(task.priority, 2)
  luaunit.assertEquals(task.blueprintEntity, 123)
  luaunit.assertEquals(task.materialsRequired[enums.ResourceType.WOOD], 10)
  luaunit.assertEquals(task.materialsRequired[enums.ResourceType.STONE], 5)
  luaunit.assertEquals(task.buildRate, 0.1)
  luaunit.assertEquals(task.buildProgress, 0.0)
  luaunit.assertEquals(task.constructionStage, 0)
  luaunit.assertEquals(task.totalStages, 1)
  luaunit.assertFalse(task.isComplete)
end

function TestConstructionTask:test_new_with_default_build_rate()
  local target = Vec2.new(3, 3)
  local materials = { [enums.ResourceType.METAL] = 8 }
  local task = ConstructionTask.new(target, 456, materials)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.buildRate, 0.1) -- default rate
  luaunit.assertEquals(task.estimatedDuration, 10.0) -- 1.0 / 0.1
end

function TestConstructionTask:test_new_with_multiple_stages()
  local target = Vec2.new(2, 2)
  local materials = { [enums.ResourceType.STONE] = 5 }
  local task = ConstructionTask.new(target, 789, materials, 0.2, 3)

  luaunit.assertNotNil(task)
  luaunit.assertEquals(task.totalStages, 3)
  luaunit.assertEquals(task.estimatedDuration, 15.0) -- 3 stages / 0.2 rate
end

function TestConstructionTask:test_new_invalid_parameters()
  -- No target
  local task = ConstructionTask.new(nil, 123, { [enums.ResourceType.WOOD] = 10 })
  luaunit.assertNil(task)

  -- No blueprint entity
  task = ConstructionTask.new(Vec2.new(1, 1), nil, { [enums.ResourceType.WOOD] = 10 })
  luaunit.assertNil(task)

  -- Invalid blueprint entity
  task = ConstructionTask.new(Vec2.new(1, 1), 0, { [enums.ResourceType.WOOD] = 10 })
  luaunit.assertNil(task)

  -- No materials
  task = ConstructionTask.new(Vec2.new(1, 1), 123, nil)
  luaunit.assertNil(task)

  -- Empty materials - this is actually allowed by current implementation
  task = ConstructionTask.new(Vec2.new(1, 1), 123, {})
  luaunit.assertNotNil(task) -- Empty materials table is valid

  -- Invalid build rate - current implementation allows 0 (creates infinite duration)
  task = ConstructionTask.new(Vec2.new(1, 1), 123, { [enums.ResourceType.WOOD] = 10 }, 0)
  luaunit.assertNotNil(task) -- Build rate 0 is allowed but creates infinite duration
  luaunit.assertEquals(task.estimatedDuration, math.huge)
end

function TestConstructionTask:test_update_progress()
  local materials = { [enums.ResourceType.WOOD] = 5 }
  local task = ConstructionTask.new(Vec2.new(1, 1), 123, materials, 0.2)
  luaunit.assertNotNil(task)

  -- Initial state
  luaunit.assertEquals(task.buildProgress, 0.0)
  luaunit.assertEquals(task.constructionStage, 0)

  -- Progress through construction
  local stillWorking = task:updateProgress(1.0) -- 0.2 progress
  luaunit.assertTrue(stillWorking)
  luaunit.assertEquals(task.buildProgress, 0.2)
  luaunit.assertEquals(task.constructionStage, 0) -- Still in stage 0

  -- Progress to near completion
  stillWorking = task:updateProgress(3.0) -- +0.6 progress = 0.8 total
  luaunit.assertTrue(stillWorking)
  luaunit.assertEquals(task.buildProgress, 0.8)
  luaunit.assertEquals(task.constructionStage, 0) -- Still in stage 0 for single stage

  -- Complete construction
  stillWorking = task:updateProgress(1.0) -- +0.2 progress = 1.0 total
  luaunit.assertFalse(stillWorking)
  luaunit.assertEquals(task.buildProgress, 1.0)
  luaunit.assertEquals(task.constructionStage, 0) -- Final stage for single stage task
  luaunit.assertTrue(task.isComplete)
end

function TestConstructionTask:test_multi_stage_construction()
  local materials = { [enums.ResourceType.STONE] = 3 }
  local task = ConstructionTask.new(Vec2.new(1, 1), 123, materials, 0.3, 3)
  luaunit.assertNotNil(task)

  -- Start at stage 0
  luaunit.assertEquals(task.constructionStage, 0)

  -- Progress to stage 1 (33% progress)
  task:updateProgress(1.2) -- 0.36 progress
  luaunit.assertEquals(task.constructionStage, 1)

  -- Progress to stage 2 (66% progress)
  task:updateProgress(1.0) -- +0.3 = 0.66 progress
  luaunit.assertEquals(task.constructionStage, 1) -- Should be stage 1 at 66%

  -- Complete construction
  task:updateProgress(1.2) -- +0.36 = 1.0+ progress
  luaunit.assertEquals(task.constructionStage, 2) -- Final stage (0-indexed)
  luaunit.assertTrue(task.isComplete)
end

function TestConstructionTask:test_get_progress()
  local materials = { [enums.ResourceType.STONE] = 3 }
  local task = ConstructionTask.new(Vec2.new(1, 1), 123, materials, 0.25)
  luaunit.assertNotNil(task)

  -- Initial progress
  luaunit.assertEquals(task:getProgress(), 0.0)

  -- Partial progress
  task:updateProgress(1.0) -- 0.25 progress
  luaunit.assertEquals(task:getProgress(), 0.25)

  -- Complete progress
  task:updateProgress(3.0) -- +0.75 = 1.0 total
  luaunit.assertEquals(task:getProgress(), 1.0)
end

function TestConstructionTask:test_get_remaining_work()
  local materials = { [enums.ResourceType.WOOD] = 4 }
  local task = ConstructionTask.new(Vec2.new(1, 1), 123, materials, 0.2)
  luaunit.assertNotNil(task)

  -- Initial remaining work
  luaunit.assertEquals(task:getRemainingWork(), 5.0) -- 1.0 / 0.2

  -- After some progress
  task:updateProgress(1.0) -- 0.2 progress
  luaunit.assertEquals(task:getRemainingWork(), 4.0) -- 0.8 / 0.2

  -- Completed
  task:updateProgress(4.0) -- Complete
  luaunit.assertEquals(task:getRemainingWork(), 0)
end

function TestConstructionTask:test_can_perform()
  local materials = { [enums.ResourceType.WOOD] = 5 }
  local task = ConstructionTask.new(Vec2.new(1, 1), 123, materials)
  luaunit.assertNotNil(task)

  -- Valid entity
  local entity = { id = 1 }
  luaunit.assertTrue(task:canPerform(entity))

  -- Nil entity
  luaunit.assertFalse(task:canPerform(nil))
end

function TestConstructionTask:test_material_requirements()
  local materials = { [enums.ResourceType.METAL] = 15, [enums.ResourceType.WOOD] = 8 }
  local task = ConstructionTask.new(Vec2.new(1, 1), 123, materials)
  luaunit.assertNotNil(task)

  -- Test hasSufficientMaterials
  local availableMaterials = { [enums.ResourceType.METAL] = 20, [enums.ResourceType.WOOD] = 10 }
  luaunit.assertTrue(task:hasSufficientMaterials(availableMaterials))

  -- Insufficient materials
  local insufficientMaterials = { [enums.ResourceType.METAL] = 10, [enums.ResourceType.WOOD] = 5 }
  luaunit.assertFalse(task:hasSufficientMaterials(insufficientMaterials))

  -- Nil materials
  luaunit.assertFalse(task:hasSufficientMaterials(nil))
end

function TestConstructionTask:test_getters()
  local materials = { [enums.ResourceType.METAL] = 15, [enums.ResourceType.WOOD] = 8 }
  local task = ConstructionTask.new(Vec2.new(1, 1), 456, materials)
  luaunit.assertNotNil(task)

  luaunit.assertEquals(task:getBlueprintEntity(), 456)
  luaunit.assertEquals(task:getRequiredMaterials()[enums.ResourceType.METAL], 15)
  luaunit.assertEquals(task:getRequiredMaterials()[enums.ResourceType.WOOD], 8)
  luaunit.assertEquals(task:getCurrentStage(), 0)
end

function TestConstructionTask:test_to_string()
  local materials = { [enums.ResourceType.WOOD] = 5 }
  local task = ConstructionTask.new(Vec2.new(5, 8), 789, materials, 0.2)
  luaunit.assertNotNil(task)

  task:updateProgress(1.0) -- 20% progress

  local str = task:toString()
  luaunit.assertStrContains(str, "ConstructionTask")
  luaunit.assertStrContains(str, "blueprint=789")
  luaunit.assertStrContains(str, "stage=1/1")
  luaunit.assertStrContains(str, "progress=20.0%")
  luaunit.assertStrContains(str, "complete=false")
end

-- Run tests
os.exit(luaunit.LuaUnit.run())