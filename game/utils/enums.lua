local enums = {}

--- @enum ComponentType
enums.ComponentType = {
  POSITION = 1,
  VELOCITY = 2,
  TASKQUEUE = 3,
  TEXTURE = 4,
  SHAPE = 5,
  TOPOGRAPHY = 6,
  MAPTILE_TAG = 7,
  SPEEDSTAT = 8, --tiles/sec
  MOVETO = 9,
  SCHEDULE = 10,
  SELECTED = 11,
  NAME = 12,
  COLONIST_TAG = 13,
  HEALTH = 14,
  -- Task Component Types (ECS-Optimized)
  TASK_COMPONENT_BASE = 100,
  MOVEMENT_TASK = 101,
  MINING_TASK = 102,
  CONSTRUCTION_TASK = 103,
  CLEANING_TASK = 104,
}

--- @enum ShapeType
enums.ShapeType = {
  CIRCLE = 1,
  SQUARE = 2,
}

--- @enum TopographyType
enums.TopographyType = {
  OPEN = 1,
  ROUGH = 2,
  INACCESSIBLE = 3,
}

--- @enum ZIndexing
enums.ZIndexing = {
  BottomBar = 0,
  RightClickMenu = 1,
  PauseMenu = 2,
}

--- @enum TaskType
enums.TaskType = {
  MOVETO = 0, -- this isn't assignable by the player, it is used before almost every other task
  --- these tasks will have a target 'health' and have similar processing
  MINE = 1,
  CONSTRUCT = 2,
  OPERATE = 3,
  FIREFIGHT = 4,
  COMBAT = 5,
  HUNT = 6,
  CLEAN = 7,
  RESEARCH = 8,
  --- these tasks have special handling
  CROP_TEND = 9,
  ANIMAL_TEND = 10,
  DOCTOR = 11,
  GUARD = 12,
}

--- @enum ToolType
enums.ToolType = {
  NONE = 0,
  PICKAXE = 1,
  SHOVEL = 2,
  HAMMER = 3,
  SAW = 4,
  BROOM = 5,
  MOP = 6,
  SCRUBBER = 7,
  WRENCH = 8,
  DRILL = 9,
}

--- @enum ResourceType
enums.ResourceType = {
  NONE = 0,
  STONE = 1,
  IRON_ORE = 2,
  GOLD_ORE = 3,
  COAL = 4,
  WOOD = 5,
  CLAY = 6,
  SAND = 7,
  WATER = 8,
  FOOD = 9,
  METAL = 10,
  BRICK = 11,
  CONCRETE = 12,
}

return enums
