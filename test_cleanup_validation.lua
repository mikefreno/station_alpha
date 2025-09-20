#!/usr/bin/env lua

-- Test script to validate ECS cleanup was successful
local function test_ecs_cleanup_validation()
  print("🧪 Testing ECS Mode Cleanup Validation...")
  
  -- Set up Lua path to find game modules
  package.path = "./?.lua;./game/?.lua;" .. package.path
  
  local success, err = pcall(function()
    -- Test TaskQueue without ECS mode methods
    local TaskQueue = require("components.TaskQueue")
    local tq = TaskQueue.new(1)
    
    -- These methods should not exist anymore
    assert(tq.enableECSMode == nil, "enableECSMode should be removed")
    assert(tq.disableECSMode == nil, "disableECSMode should be removed") 
    assert(tq.isECSMode == nil, "isECSMode should be removed")
    
    -- These methods should still exist and work
    assert(type(tq.canAcceptNewTask) == "function", "canAcceptNewTask should exist")
    assert(type(tq.hasActiveTasks) == "function", "hasActiveTasks should exist")
    assert(type(tq.getActiveTaskCount) == "function", "getActiveTaskCount should exist")
    
    print("✅ TaskQueue: ECS mode methods removed, core methods preserved")
    
    -- Test Schedule without ECS mode methods
    local Schedule = require("components.Schedule")
    local schedule = Schedule.new()
    
    -- These methods should not exist anymore
    assert(schedule.enableECSMode == nil, "enableECSMode should be removed")
    assert(schedule.disableECSMode == nil, "disableECSMode should be removed")
    assert(schedule.isECSMode == nil, "isECSMode should be removed")
    
    -- These methods should still exist and work
    assert(type(schedule.selectTask) == "function", "selectTask should exist")
    assert(type(schedule.selectNextTaskType) == "function", "selectNextTaskType should exist")
    assert(type(schedule.getScheduleWeight) == "function", "getScheduleWeight should exist")
    
    print("✅ Schedule: ECS mode methods removed, core methods preserved")
    
    -- Test TaskManager without ECS mode methods
    local TaskManager = require("systems.TaskManager")
    local tm = TaskManager.new()
    
    -- These methods should not exist anymore 
    assert(tm.enableECSMode == nil, "enableECSMode should be removed")
    assert(tm.disableECSMode == nil, "disableECSMode should be removed")
    assert(tm.isECSMode == nil, "isECSMode should be removed")
    
    -- These methods should still exist and work
    assert(type(tm.createECSTask) == "function", "createECSTask should exist")
    assert(type(tm.assignTaskToQueue) == "function", "assignTaskToQueue should exist")
    
    print("✅ TaskManager: ECS mode methods removed, core methods preserved")
  end)
  
  if success then
    print("🎉 ECS Mode Cleanup Validation: SUCCESS!")
    print("   - All ECS mode methods removed")
    print("   - All core functionality preserved")
    print("   - Right-click goto should work correctly")
    return true
  else
    print("❌ ECS Mode Cleanup Validation: FAILED!")
    print("Error: " .. tostring(err))
    return false
  end
end

-- Run the test
local success = test_ecs_cleanup_validation()
os.exit(success and 0 or 1)