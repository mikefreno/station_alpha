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
    SCHEDULE = 10,
    SELECTED = 11,
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

--- @enum Placement
enums.Placement = {
    TOP_LEFT = 1,
    TOP_CENTER = 2,
    TOP_RIGHT = 3,
    CENTER_LEFT = 4,
    CENTER_RIGHT = 5,
    CENTER_CENTER = 6,
    BOTTOM_LEFT = 7,
    BOTTOM_CENTER = 8,
    BOTTOM_RIGHT = 9,
}

return enums
