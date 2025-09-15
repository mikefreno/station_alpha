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

--- @enum TaskType
enums.TaskType = {
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

return enums
