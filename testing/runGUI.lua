package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")

-- Run only GUI tests in the flexlove directory
local testFiles = {
  "game/libs/testing/absolute-positioning.lua",
  "game/libs/testing/align-items-tests.lua",
  "game/libs/testing/align-self-tests.lua",
  "game/libs/testing/flex-container-tests.lua",
  "game/libs/testing/flex-direction-tests.lua",
  "game/libs/testing/justify-content-tests.lua",
  "game/libs/testing/nested-layout-tests.lua",
}

-- Run all tests, but don't exit on error
local success = true
print("========================================")
print("Running GUI tests")
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
print("All GUI tests completed")
print("========================================")

-- Run the tests and exit with appropriate code
local result = luaunit.LuaUnit.run()
os.exit(success and result or 1)
