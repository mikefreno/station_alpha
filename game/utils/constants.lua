local MAP_W, MAP_H = 100, 75 -- logical grid size
local LOGICAL_TILE_SIZE = 1 -- 1 logical unit == 1 tile
local LOGICAL_TO_PIXEL = 32 -- 32 pixels per tile (default)

-- this will be recomputed on resize
local pixelSize = LOGICAL_TO_PIXEL

return {
  MAP_W = MAP_W,
  MAP_H = MAP_H,
  LOGICAL_TILE_SIZE = LOGICAL_TILE_SIZE,
  pixelSize = pixelSize,
}
