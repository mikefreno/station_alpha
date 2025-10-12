-- Grid Positioning Issue Test
-- Reproduces the grid positioning problem described in BottomBar.lua

package.path = package.path .. ";?.lua"

local lu = require("testing/luaunit")
require("testing/loveStub") -- Required to mock LOVE functions
local FlexLove = require("FlexLove")
local Gui = FlexLove.GUI
local Color = FlexLove.Color
local enums = FlexLove.enums

TestGridPositioningIssue = {}

function TestGridPositioningIssue:setUp()
  -- Reset GUI before each test
  Gui.destroy()
  Gui.init({})
end

function TestGridPositioningIssue:tearDown()
  Gui.destroy()
end

-- ====================
-- Grid Positioning Issue Reproduction
-- ====================

function TestGridPositioningIssue:test_grid_container_as_child_of_parent_element()
  -- Create a parent container (similar to BottomBar.window)
  local parentContainer = Gui.new({
    x = 100,
    y = 100,
    width = 400,
    height = 200,
    background = Color.new(0.5, 0.5, 0.5, 1),
  })
  
  -- Create a grid container as child of parent (similar to BottomBar.scheduleContainer)
  local gridContainer = Gui.new({
    parent = parentContainer,
    width = "100%",
    height = "100%",
    positioning = enums.Positioning.GRID,
    gridTemplateColumns = "repeat(3, 1fr)",
    gridTemplateRows = "repeat(2, 1fr)",
    columnGap = 5,
    rowGap = 5,
    padding = { top = 5, right = 5, bottom = 5, left = 5 },
    background = Color.new(0.2, 0.2, 0.2, 0.8),
  })
  
  -- Add some items to the grid
  local items = {}
  for i = 1, 6 do
    items[i] = Gui.new({
      parent = gridContainer,
      width = 30,
      height = 30,
      background = Color.new(0.6, 0.2, 0.4),
    })
  end
  
  -- Test that the grid container is positioned correctly relative to its parent
  lu.assertAlmostEquals(gridContainer.x, 105, 1) -- Should be at parent's x + padding.left
  lu.assertAlmostEquals(gridContainer.y, 105, 1) -- Should be at parent's y + padding.top
  
  -- Test that grid items are positioned correctly within the grid container
  -- First item should be at (105, 105) - parent x + padding.left + padding.top
  lu.assertAlmostEquals(items[1].x, 105, 1)
  lu.assertAlmostEquals(items[1].y, 105, 1)
  
  -- Second item should be at (140, 105) - first column width + gap + padding
  lu.assertAlmostEquals(items[2].x, 140, 1)
  lu.assertAlmostEquals(items[2].y, 105, 1)
  
  -- Third item should be at (275, 105) - first column width + gap + second column width + gap + padding
  lu.assertAlmostEquals(items[3].x, 275, 1)
  lu.assertAlmostEquals(items[3].y, 105, 1)
end

function TestGridPositioningIssue:test_grid_with_absolute_positioning_parent()
  -- Create a parent with absolute positioning (like BottomBar.window)
  local parentContainer = Gui.new({
    x = 50,
    y = 50,
    width = 300,
    height = 150,
    positioning = enums.Positioning.ABSOLUTE, -- Explicitly absolute
    background = Color.new(0.5, 0.5, 0.5, 1),
  })
  
  -- Create a grid container as child (similar to BottomBar.scheduleContainer)
  local gridContainer = Gui.new({
    parent = parentContainer,
    width = "100%",
    height = "100%",
    positioning = enums.Positioning.GRID,
    gridTemplateColumns = "repeat(2, 1fr)",
    gridTemplateRows = "repeat(3, 1fr)",
    columnGap = 2,
    rowGap = 2,
    padding = { top = 2, right = 2, bottom = 2, left = 2 },
    background = Color.new(0.1, 0.1, 0.1, 0.8),
  })
  
  -- Add items to the grid
  local items = {}
  for i = 1, 6 do
    items[i] = Gui.new({
      parent = gridContainer,
      width = 20,
      height = 20,
      background = Color.new(0.6, 0.2, 0.4),
    })
  end
  
  -- Test that the grid container is positioned correctly within its parent
  lu.assertAlmostEquals(gridContainer.x, 52, 1) -- Should be at parent's x + padding.left
  lu.assertAlmostEquals(gridContainer.y, 52, 1) -- Should be at parent's y + padding.top
  
  -- Test that the first item is positioned correctly within grid container
  lu.assertAlmostEquals(items[1].x, 52, 1) -- x = parent.x + padding.left + item.x (relative to grid cell)
  lu.assertAlmostEquals(items[1].y, 52, 1) -- y = parent.y + padding.top + item.y (relative to grid cell)
end

function TestGridPositioningIssue:test_nested_grid_positioning()
  -- Create a parent container
  local parentContainer = Gui.new({
    x = 0,
    y = 0,
    width = 400,
    height = 300,
    background = Color.new(0.5, 0.5, 0.5, 1),
  })
  
  -- Create a flex container as child (like in BottomBar)
  local flexContainer = Gui.new({
    parent = parentContainer,
    width = "100%",
    height = "100%",
    positioning = enums.Positioning.FLEX,
    flexDirection = enums.FlexDirection.VERTICAL,
    justifyContent = enums.JustifyContent.CENTER,
    alignItems = enums.AlignItems.CENTER,
  })
  
  -- Create a grid container as child of flex container (the issue case)
  local gridContainer = Gui.new({
    parent = flexContainer,
    width = "80%",
    height = "80%",
    positioning = enums.Positioning.GRID,
    gridTemplateColumns = "repeat(4, 1fr)",
    gridTemplateRows = "repeat(2, 1fr)",
    columnGap = 5,
    rowGap = 5,
    padding = { top = 5, right = 5, bottom = 5, left = 5 },
    background = Color.new(0.2, 0.2, 0.2, 0.8),
  })
  
  -- Add items to the grid
  local items = {}
  for i = 1, 8 do
    items[i] = Gui.new({
      parent = gridContainer,
      width = 30,
      height = 30,
      background = Color.new(0.6, 0.2, 0.4),
    })
  end
  
  -- Test that the grid container is positioned correctly within its flex parent
  lu.assertAlmostEquals(gridContainer.x, 80, 1) -- Should be at (400 - 320) / 2 = 40 + padding.left
  lu.assertAlmostEquals(gridContainer.y, 75, 1) -- Should be at (300 - 240) / 2 = 30 + padding.top
  
  -- Test that items are positioned correctly within grid container
  lu.assertAlmostEquals(items[1].x, 85, 1)
  lu.assertAlmostEquals(items[1].y, 80, 1)
end

-- Run the tests
local result = lu.LuaUnit.run()
print("Running Grid Positioning Issue Tests...")
os.exit(result)