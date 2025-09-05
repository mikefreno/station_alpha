local enums = {}

--- @enum ComponentType
enums.ComponentType = {
    POSITION = 1,
    VELOCITY = 2,
    TASKQUEUE = 3,
    TEXTURE = 4,
    SHAPE = 5,
    TOPOGRAPHY = 6,
    MAPTILETAG = 7,
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

return enums
