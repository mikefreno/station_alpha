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
}

--- @enum ActionType
enums.ActionType = {
  MOVETO = 1,
  WORK = 2,
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
  MINE = 1,
  CONSTRUCT = 2,
  OPERATE = 3,
  CROP_TEND = 4,
  ANIMAL_TEND = 5,
  DOCTOR = 6,
  FIREFIGHT = 7,
  COMBAT = 8,
  GUARD = 9,
  RESEARCH = 10,
  CLEAN = 11,
}

return enums
