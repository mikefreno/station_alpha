local Enums = {}

--- @enum ComponentType
Enums.ComponentType = {
    POSITION = 1,
    VELOCITY = 2,
    TASKQUEUE = 3,
    TEXTURE = 4,
    SHAPE = 5
}

--- @enum Tasks
Enums.Tasks = {
    MOVETO = 1,
}

--- @enum Shapes
Enums.Shapes = {
    CIRCLE = 1,
    SQUARE = 2
}

return Enums
