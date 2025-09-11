local MAP_W, MAP_H = 100, 75 -- logical grid size
local LOGICAL_TILE_SIZE = 1 -- 1 logical unit == 1 tile

local pixelSize = 32 -- 32 pixels per tile (default: 1280 / 40)

return {
  MAP_W = MAP_W,
  MAP_H = MAP_H,
  LOGICAL_TILE_SIZE = LOGICAL_TILE_SIZE,
  pixelSize = pixelSize,
}
