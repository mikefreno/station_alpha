package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"
local luaunit = require("testing.luaunit")
local Gui = require("libs.MyGUI")

TestMyGUIPositioning = {}

function TestMyGUIPositioning:testAbsolutePositioning()
  -- Create a window with absolute positioning
  local window = Gui.Window.new({
    x = 100,
    y = 100,
    w = 200,
    h = 150,
    positioning = Gui.Positioning.ABSOLUTE,
  })

  -- Create a child button with absolute positioning
  local button = Gui.Button.new({
    parent = window,
    x = 20,
    y = 30,
    w = 50,
    h = 30,
    text = "Test Button",
    positioning = Gui.Positioning.ABSOLUTE,
  })

  -- Verify child position is absolute (should be at 120, 130)
  luaunit.assertAlmostEquals(button.x, 20, 0.001)
  luaunit.assertAlmostEquals(button.y, 30, 0.001)
end

function TestMyGUIPositioning:testFlexHorizontalPositioning()
  -- Create a window with flex horizontal positioning
  local window = Gui.Window.new({
    x = 100,
    y = 100,
    w = 300,
    h = 150,
    positioning = Gui.Positioning.FLEX,
    flexDirection = Gui.FlexDirection.HORIZONTAL,
    justifyContent = Gui.JustifyContent.FLEX_START,
  })

  -- Create children buttons with flex positioning
  local button1 = Gui.Button.new({
    parent = window,
    w = 50,
    h = 30,
    text = "Button 1",
  })

  local button2 = Gui.Button.new({
    parent = window,
    w = 60,
    h = 30,
    text = "Button 2",
  })

  -- Verify child positions are calculated correctly
  luaunit.assertAlmostEquals(button1.x, 100, 0.001)
  luaunit.assertAlmostEquals(button1.y, 100, 0.001)
  luaunit.assertAlmostEquals(button2.x, 150, 0.001)
  luaunit.assertAlmostEquals(button2.y, 100, 0.001)
end

function TestMyGUIPositioning:testFlexVerticalPositioning()
  -- Create a window with flex vertical positioning
  local window = Gui.Window.new({
    x = 100,
    y = 100,
    w = 200,
    h = 300,
    positioning = Gui.Positioning.FLEX,
    flexDirection = Gui.FlexDirection.VERTICAL,
    justifyContent = Gui.JustifyContent.CENTER,
  })

  -- Create children buttons with flex positioning
  local button1 = Gui.Button.new({
    parent = window,
    w = 50,
    h = 30,
    text = "Button 1",
  })

  local button2 = Gui.Button.new({
    parent = window,
    w = 60,
    h = 30,
    text = "Button 2",
  })

  -- Verify child positions are calculated correctly
  luaunit.assertAlmostEquals(button1.x, 100, 0.001)
  luaunit.assertAlmostEquals(button1.y, 135, 0.001)
  luaunit.assertAlmostEquals(button2.x, 100, 0.001)
  luaunit.assertAlmostEquals(button2.y, 165, 0.001)
end

function TestMyGUIPositioning:testAlignItemsStretch()
  -- Create a window with flex positioning and stretch alignment
  local window = Gui.Window.new({
    x = 100,
    y = 100,
    w = 200,
    h = 150,
    positioning = Gui.Positioning.FLEX,
    flexDirection = Gui.FlexDirection.HORIZONTAL,
    alignItems = Gui.AlignItems.STRETCH,
  })

  -- Create children buttons with flex positioning
  local button1 = Gui.Button.new({
    parent = window,
    w = 50,
    h = 30,
    text = "Button 1",
  })

  local button2 = Gui.Button.new({
    parent = window,
    w = 60,
    h = 30,
    text = "Button 2",
  })

  -- Verify child heights are stretched to full window height
  luaunit.assertAlmostEquals(button1.height, 150, 0.001)
  luaunit.assertAlmostEquals(button2.height, 150, 0.001)
end

function TestMyGUIPositioning:testAlignItemsCenter()
  -- Create a window with flex positioning and center alignment
  local window = Gui.Window.new({
    x = 100,
    y = 100,
    w = 200,
    h = 150,
    positioning = Gui.Positioning.FLEX,
    flexDirection = Gui.FlexDirection.HORIZONTAL,
    alignItems = Gui.AlignItems.CENTER,
  })

  -- Create children buttons with flex positioning
  local button1 = Gui.Button.new({
    parent = window,
    w = 50,
    h = 30,
    text = "Button 1",
  })

  local button2 = Gui.Button.new({
    parent = window,
    w = 60,
    h = 30,
    text = "Button 2",
  })

  -- Verify child positions are centered vertically
  luaunit.assertAlmostEquals(button1.y, 60, 0.001)
  luaunit.assertAlmostEquals(button2.y, 60, 0.001)
end

return TestMyGUIPositioning
