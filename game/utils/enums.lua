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
    SPEEDSTAT = 8, --tiles/sec
    MOVETO = 9,
    CAMERA = 10,
    TASKMANAGER = 11,
    SCHEDULE = 12,
    RIGHTCLICKMENU = 13,
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
