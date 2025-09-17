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
  "testing/__tests__/flexlove/nested-layout-tests.lua",
}

-- Run all tests, but don't exit on error
local success = true
print("========================================")
print("Running ALL tests")
print("========================================")
for _, testFile in ipairs(testFiles) do
  print("========================================")
  print("Running test file: " .. testFile)
  print("========================================")
  local status, err = pcall(dofile, testFile)
  if not status then
    print("Error running test " .. testFile .. ": " .. tostring(err))
    success = false
  end
end

print("========================================")
print("All tests completed")
print("========================================")

-- Run the tests and exit with appropriate code
local result = luaunit.LuaUnit.run()
os.exit(success and result or 1)
