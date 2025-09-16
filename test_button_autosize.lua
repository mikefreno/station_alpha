#!/usr/bin/env lua

-- Test script for Button autosize functionality

package.path = '?.lua;' .. package.path
local FlexLove = require('game/libs/FlexLove')
local Gui = FlexLove.GUI

-- Create a test button with text and padding
local button = Gui.Button.new({
    text = "Test Button",
    px = 10,
    py = 5,
    textSize = 16
})

-- Test that the autosize function works
button:autosize()

print("Button width:", button.width)
print("Button height:", button.height)

-- Test with no padding
local button2 = Gui.Button.new({
    text = "Short",
    px = 0,
    py = 0,
    textSize = 16
})

button2:autosize()
print("Button2 width:", button2.width)
print("Button2 height:", button2.height)

print("Test completed successfully!")