#!/usr/bin/env lua

-- Add the current directory to the path 
package.path = package.path .. ";./?.lua;./game/?.lua;./game/components/?.lua;./game/systems/?.lua;./game/adapters/?.lua;./game/utils/?.lua"

local enums = require("game.utils.enums")
local Vec2 = require("game.utils.Vec2")
local Logger = require("logger")

local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

print("Starting TaskQueue debug...")

-- Create a simple mock TaskAdapter that actually works
local MockTaskAdapter = {
  isTaskComponent = function(self, task)
    print("MockTaskAdapter:isTaskComponent called with:", task)
    local result = task and task.componentType ~= nil
    print("isTaskComponent result:", result)
    return result
  end,
  
  canConvert = function(self, task)
    print("MockTaskAdapter:canConvert called with:", task)
    if not task then 
      print("canConvert: task is nil")
      return false 
    end
    if task.componentType then 
      print("canConvert: already has componentType") 
      return true 
    end
    
    local mapping = {
      [TaskType.MOVETO] = ComponentType.MOVEMENT_TASK,
    }
    
    local result = mapping[task.type] ~= nil
    print("canConvert result for type", task.type, ":", result)
    return result
  end,
  
  convertToECS = function(self, legacyTask, entityId)
    print("MockTaskAdapter:convertToECS called with:", legacyTask, entityId)
    
    if not legacyTask then 
      print("convertToECS: legacyTask is nil")
      return nil 
    end
    
    local componentType = ComponentType.MOVEMENT_TASK
    local component = {
      componentType = componentType,
      isComplete = false,
      priority = legacyTask.priority or 1.0,
      target = legacyTask.target,
      requiredDistance = legacyTask.requiredDistance or 0.5
    }
    
    print("convertToECS created component:", component)
    print("convertToECS returning componentType:", componentType)
    return component, componentType
  end,
  
  getTaskComponentType = function(self, task)
    print("MockTaskAdapter:getTaskComponentType called with:", task)
    if not task then return nil end
    
    if task.componentType then
      return task.componentType
    end
    
    local mapping = {
      [TaskType.MOVETO] = ComponentType.MOVEMENT_TASK,
    }
    
    local result = mapping[task.type]
    print("getTaskComponentType result:", result)
    return result
  end
}

-- Mock EntityManager
local MockEntityManager = {
  components = {},
  addComponent = function(self, entityId, componentType, component)
    print("MockEntityManager:addComponent called:", entityId, componentType, component)
    if not self.components[componentType] then
      self.components[componentType] = {}
    end
    self.components[componentType][entityId] = component
  end,
  removeComponent = function(self, entityId, componentType)
    print("MockEntityManager:removeComponent called:", entityId, componentType)
    if self.components[componentType] then
      self.components[componentType][entityId] = nil
    end
  end
}

-- Mock TaskComponentPool
local MockTaskComponentPool = {
  release = function(self, componentType, component)
    print("MockTaskComponentPool:release called:", componentType, component)
  end
}

-- Override require to return our mocks
local originalRequire = require
function require(module)
  if module == "game.adapters.TaskAdapter" then
    return MockTaskAdapter
  elseif module == "game.systems.EntityManager" then
    return MockEntityManager
  elseif module == "game.systems.TaskComponentPool" then
    return MockTaskComponentPool
  else
    return originalRequire(module)
  end
end

-- Now require TaskQueue
local TaskQueue = require("game.components.TaskQueue")

print("Creating TaskQueue...")
local taskQueue = TaskQueue.new(123)

print("Creating legacy task...")
local legacyTask = {
  type = TaskType.MOVETO,
  target = Vec2.new(5, 5),
  priority = 1.0,
  requiredDistance = 0.5
}

print("Pushing legacy task...")
taskQueue:push(legacyTask)

print("Active task count:", taskQueue:getActiveTaskCount())
print("Has active tasks:", taskQueue:hasActiveTasks())

print("Done.")