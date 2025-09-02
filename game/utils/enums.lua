local Enums = {}

--- @enum ComponentType
Enums.ComponentType = {
  POSITION = 1,
  VELOCITY = 2,
  TASKQUEUE = 3,
  TEXTURE = 4,
  SHAPE = 5,
  TOPOGRAPHY = 6,
}

--- @enum TaskType
Enums.TaskType = {
  MOVETO = 1,
}

--- @enum ShapeType
Enums.ShapeType = {
  CIRCLE = 1,
  SQUARE = 2,
}

--- @enum TopographyType
Enums.TopographType = {
  OPEN = 1,
  ROUGH = 2,
  INACCESSIBLE = 3,
}

return Enums
