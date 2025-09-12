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
  NAME = 12,
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

--- @enum TextAlign
enums.TextAlign = {
  START = "start",
  CENTER = "center",
  END = "end",
  JUSTIFY = "justify",
}

--- @enum Positioning
enums.Positioning = {
  ABSOLUTE = "absolute",
  FLEX = "flex",
}

--- @enum FlexDirection
enums.FlexDirection = {
  HORIZONTAL = "horizontal",
  VERTICAL = "vertical",
}

--- @enum JustifyContent
enums.JustifyContent = {
  FLEX_START = "flex-start",
  CENTER = "center",
  SPACE_AROUND = "space-around",
  FLEX_END = "flex-end",
  SPACE_EVENLY = "space-evenly",
  SPACE_BETWEEN = "space-between",
}

--- @enum AlignItems
enums.AlignItems = {
  STRETCH = "stretch",
  FLEX_START = "flex-start",
  FLEX_END = "flex-end",
  CENTER = "center",
  BASELINE = "baseline",
}

--- @enum AlignContent
enums.AlignContent = {
  STRETCH = "stretch",
  FLEX_START = "flex-start",
  FLEX_END = "flex-end",
  CENTER = "center",
  SPACE_BETWEEN = "space-between",
  SPACE_AROUND = "space-around",
}

return enums
