package.path = package.path .. ";./?.lua;./game/?.lua;./game/utils/?.lua;./game/components/?.lua;./game/systems/?.lua"

local luaunit = require("testing.luaunit")

-- Run all tests in the __tests__ directory
local testFiles = {
  "testing/__tests__/pathfinder.lua",
  "testing/__tests__/task_component.lua",
  "testing/__tests__/task_component_pool.lua",
  "testing/__tests__/task_execution_system.lua",
  "testing/__tests__/task_execution_system_integration.lua",
  "testing/__tests__/task_dependency_resolver.lua",
  "testing/__tests__/movement_system.lua",
  "testing/__tests__/mining_processor.lua",
  "testing/__tests__/construction_processor.lua",
  "testing/__tests__/cleaning_processor.lua",
  "testing/__tests__/system_integration.lua",
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
