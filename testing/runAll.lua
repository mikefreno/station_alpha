package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")

-- Run all tests in the __tests__ directory
local testFiles = {
  "testing/__tests__/pathfinder.lua",
  "testing/__tests__/flexlove/absolute-positioning.lua",
  "testing/__tests__/flexlove/align-items-tests.lua",
  "testing/__tests__/flexlove/align-self-tests.lua",
  "testing/__tests__/flexlove/flex-container-tests.lua",
  "testing/__tests__/flexlove/flex-direction-tests.lua",
  "testing/__tests__/flexlove/justify-content-tests.lua",
  "testing/__tests__/flexlove/nested-layout-tests.lua"
}

for _, testFile in ipairs(testFiles) do
  print("Running test: " .. testFile)
  dofile(testFile)
end

-- Run the tests
os.exit(luaunit.LuaUnit.run())