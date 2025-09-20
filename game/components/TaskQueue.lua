local enums = require("game.utils.enums")
local MoveTo = require("game.components.MoveTo")
local Vec2 = require("game.utils.Vec2")
local Logger = require("logger")
local TaskAdapter = require("game.adapters.TaskAdapter")
local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

---@class TaskQueue
---@field ownerId integer
---@field activeTaskComponents table<ComponentType, TaskComponent> -- Active task components
---@field maxConcurrentTasks integer -- Number of simultaneous tasks (default 1)
local TaskQueue = {}

---@param ownerId integer
function TaskQueue.new(ownerId)
  local self = setmetatable({}, { __index = TaskQueue })
  self.ownerId = ownerId
  
  -- ECS integration fields (always enabled)
  self.activeTaskComponents = {}
  self.maxConcurrentTasks = 1
  
  return self
end

function TaskQueue:reset()
  -- Properly clean up active task components
  for componentType, taskComponent in pairs(self.activeTaskComponents) do
    -- Remove from EntityManager
    local EntityManager = require("game.systems.EntityManager")
    EntityManager:removeComponent(self.ownerId, componentType)
    
    -- Release back to component pool
    local TaskComponentPool = require("game.systems.TaskComponentPool")
    TaskComponentPool:release(componentType, taskComponent)
    
    Logger:info("TaskQueue: Released ECS component type " .. tostring(componentType) .. " during reset")
  end
  
  -- Clear active task components
  self.activeTaskComponents = {}
  
  Logger:info("TaskQueue: Reset completed for entity " .. self.ownerId)
end

function TaskQueue:push(task)
  -- Add to active components if possible
  if self:canAcceptNewTask() then
    local taskComponent = nil
    local componentType = nil
    
    -- Check if it's already a task component
    if TaskAdapter:isTaskComponent(task) then
      taskComponent = task
    elseif TaskAdapter:canConvert(task) then
      -- Convert legacy task to ECS component using TaskAdapter
      taskComponent, componentType = TaskAdapter:convertToECS(task, self.ownerId)
      if not taskComponent then
        Logger:error("TaskQueue: Failed to convert legacy task to ECS component")
        return
      end
    else
      Logger:error("TaskQueue: Cannot convert task to ECS component - unsupported task type")
      return
    end
    
    -- Only try getTaskComponentType if we don't already have it from conversion
    if not componentType then
      componentType = TaskAdapter:getTaskComponentType(taskComponent)
    end
    if componentType then
      self.activeTaskComponents[componentType] = taskComponent
      
      -- Add the component to EntityManager
      local EntityManager = require("game.systems.EntityManager")
      EntityManager:addComponent(self.ownerId, componentType, taskComponent)
      
      Logger:info("TaskQueue: Added ECS task component type " .. tostring(componentType) .. " to entity " .. self.ownerId)
    else
      Logger:error("TaskQueue: Failed to determine component type for ECS task")
      -- Release the component if it was acquired from the pool
      if TaskAdapter:isTaskComponent(taskComponent) then
        local TaskComponentPool = require("game.systems.TaskComponentPool")
        local compType = TaskAdapter:getTaskComponentType(taskComponent)
        if compType then
          TaskComponentPool:release(compType, taskComponent)
        end
      end
    end
  else
    Logger:warn("TaskQueue: Cannot accept new task - at maximum concurrent tasks")
  end
end

function TaskQueue:pop()
  -- Get the next completed task component
  for componentType, taskComponent in pairs(self.activeTaskComponents) do
    if taskComponent.isComplete then
      self.activeTaskComponents[componentType] = nil
      
      -- Remove from EntityManager
      local EntityManager = require("game.systems.EntityManager")
      EntityManager:removeComponent(self.ownerId, componentType)
      
      -- Release back to component pool
      local TaskComponentPool = require("game.systems.TaskComponentPool")
      TaskComponentPool:release(componentType, taskComponent)
      
      Logger:info("TaskQueue: Completed and cleaned up ECS task component type " .. tostring(componentType))
      return taskComponent
    end
  end
  return nil
end

---@param dt number
function TaskQueue:update(dt)
  -- TaskExecutionSystem handles updates
  -- Just check for completed tasks and clean them up
  for componentType, taskComponent in pairs(self.activeTaskComponents) do
    if taskComponent.isComplete then
      Logger:info("TaskQueue: ECS task completed: " .. tostring(componentType))
      
      -- Remove from active components
      self.activeTaskComponents[componentType] = nil
      
      -- Remove from EntityManager
      local EntityManager = require("game.systems.EntityManager")
      EntityManager:removeComponent(self.ownerId, componentType)
      
      -- Release back to component pool
      local TaskComponentPool = require("game.systems.TaskComponentPool")
      TaskComponentPool:release(componentType, taskComponent)
      
      Logger:info("TaskQueue: Cleaned up completed ECS task component type " .. tostring(componentType))
    end
  end
end

---Check if TaskQueue can accept new tasks
---@return boolean
function TaskQueue:canAcceptNewTask()
  local activeCount = 0
  for _, _ in pairs(self.activeTaskComponents) do
    activeCount = activeCount + 1
  end
  return activeCount < self.maxConcurrentTasks
end

---Get the ComponentType for a task object using TaskAdapter
---@param task any
---@return ComponentType|nil
function TaskQueue:getTaskComponentType(task)
  return TaskAdapter:getTaskComponentType(task)
end

---Add a movement task using ECS components
---@param targetPosition Vec2
---@return boolean success
function TaskQueue:addMovementTask(targetPosition)
  if not self:canAcceptNewTask() then
    Logger:warn("TaskQueue: Cannot add movement task - at maximum concurrent tasks")
    return false
  end
  
  -- Create a basic legacy-style movement task data for conversion
  local legacyTask = {
    type = TaskType.MOVETO,
    target = targetPosition,
    priority = 1.0,
    requiredDistance = 0.5
  }
  
  -- Use TaskAdapter to convert to ECS component
  local movementTask, returnedComponentType = TaskAdapter:convertToECS(legacyTask, self.ownerId)
  if not movementTask then
    Logger:error("TaskQueue: Failed to create MovementTask via TaskAdapter")
    return false
  end
  
  local componentType = ComponentType.MOVEMENT_TASK
  self.activeTaskComponents[componentType] = movementTask
  
  -- Add the component to EntityManager
  local EntityManager = require("game.systems.EntityManager")
  EntityManager:addComponent(self.ownerId, componentType, movementTask)
  
  Logger:info("TaskQueue: Added movement task to entity " .. self.ownerId)
  return true
end

---Get the current active task count
---@return integer
function TaskQueue:getActiveTaskCount()
  local count = 0
  for _, _ in pairs(self.activeTaskComponents) do
    count = count + 1
  end
  return count
end

---Check if TaskQueue has any active tasks
---@return boolean
function TaskQueue:hasActiveTasks()
  for _, _ in pairs(self.activeTaskComponents) do
    return true
  end
  return false
end

---Check if TaskQueue is empty (no active tasks)
---@return boolean
function TaskQueue:isEmpty()
  return not self:hasActiveTasks()
end

---Clean up all resources when TaskQueue is destroyed
function TaskQueue:destroy()
  Logger:info("TaskQueue: Destroying TaskQueue for entity " .. self.ownerId)
  
  -- Clean up all ECS components
  for componentType, taskComponent in pairs(self.activeTaskComponents) do
    -- Remove from EntityManager
    local EntityManager = require("game.systems.EntityManager")
    EntityManager:removeComponent(self.ownerId, componentType)
    
    -- Release back to component pool
    local TaskComponentPool = require("game.systems.TaskComponentPool")
    TaskComponentPool:release(componentType, taskComponent)
    
    Logger:info("TaskQueue: Released ECS component type " .. tostring(componentType) .. " during destruction")
  end
  
  self.activeTaskComponents = {}
  Logger:info("TaskQueue: Destruction completed for entity " .. self.ownerId)
end

return TaskQueue
