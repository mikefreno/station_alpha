local enum = require("game.utils.enums")
local ComponentType = enum.ComponentType
local TaskType = enum.TaskType
local Vec2 = require("game.utils.Vec2")
local Logger = require("logger")

---@class TaskManager
---@field openTasks table<TaskType, table<integer, Task>>
---@field taskExecutionSystem table TaskExecutionSystem instance
---@field taskComponentPool table TaskComponentPool instance
local TaskManager = {}
TaskManager.__index = TaskManager

---@return TaskManager
function TaskManager.new()
  local self = setmetatable({}, TaskManager)
  self.openTasks = {}

  -- ECS integration fields (always enabled)
  self.taskExecutionSystem = nil
  self.taskComponentPool = nil

  -- Initialize ECS systems immediately
  self:initializeECSSystems()

  return self
end

---@param dt number
function TaskManager:update(dt)
  -- ECS mode: delegate to TaskExecutionSystem
  if self.taskExecutionSystem then
    self.taskExecutionSystem:update(dt)
  end

  -- Handle task assignment for idle entities
  self:assignTasksToIdleEntities(dt)
end

---@param taskType TaskType
---@param task any
function TaskManager:addTask(taskType, task)
  table.insert(self.openTasks[taskType], task)
end

---helper function to add a full path in sequence to the queue
---@param entity integer
---@param path table<integer, Vec2>
function TaskManager:newPath(entity, path)
  if path and #path > 0 then
    local taskQueue = EntityManager:getComponent(entity, ComponentType.TASKQUEUE)
    if taskQueue then
      taskQueue:reset()
      
      -- ECS mode: create MovementTask components for each waypoint
      for _, wp in ipairs(path) do
        if not taskQueue:addMovementTask(wp) then
          Logger:error("TaskManager: Failed to add movement task for waypoint")
          break
        end
      end
    end
  end
end

---Handle task assignment for idle entities (ECS mode)
---@param dt number
function TaskManager:assignTasksToIdleEntities(openTasksOrDt)
  -- If openTasks provided (not just dt), assign tasks to idle entities
  if openTasksOrDt and type(openTasksOrDt) == "table" then
    self:assignOpenTasksToIdleEntities(openTasksOrDt)
  end
end

---Assign tasks from openTasks table to idle entities
---@param openTasks table<TaskType, table<Vec2>>
function TaskManager:assignOpenTasksToIdleEntities(openTasks)
  local EntityManager = require("game.systems.EntityManager")
  
  -- Find entities that have TaskQueue and are idle (no active tasks)
  for entityId, _ in pairs(EntityManager.entities) do
    local taskQueue = EntityManager:getComponent(entityId, ComponentType.TASKQUEUE)
    local schedule = EntityManager:getComponent(entityId, ComponentType.SCHEDULE)
    
    if taskQueue and taskQueue:isEmpty() then
      -- Entity is idle, try to assign a task based on schedule weights
      local assignedTask = self:findBestTaskForEntity(entityId, schedule, openTasks)
      if assignedTask then
        local success = self:assignTaskToQueue(entityId, assignedTask)
        if success then
          Logger:debug("TaskManager: Assigned task to idle entity " .. entityId)
        end
      end
    end
  end
end

---Find the best task for an entity based on its schedule weights
---@param entityId integer
---@param schedule Schedule|nil
---@param openTasks table<TaskType, table<Vec2>>
---@return table|nil task The best task for this entity, or nil if none found
function TaskManager:findBestTaskForEntity(entityId, schedule, openTasks)
  if not openTasks then
    return nil
  end
  
  -- If no schedule, assign any available task
  if not schedule then
    for taskType, tasks in pairs(openTasks) do
      if tasks and #tasks > 0 then
        local task = table.remove(tasks, 1) -- Take first available task
        return self:createTaskFromTypeAndTarget(taskType, task)
      end
    end
    return nil
  end
  
  -- Find task type with highest weight that has available tasks
  local bestTaskType = nil
  local bestWeight = 0
  
  for taskType, tasks in pairs(openTasks) do
    if tasks and #tasks > 0 then
      local weight = schedule:getScheduleWeight(taskType) or 0
      if weight > bestWeight then
        bestWeight = weight
        bestTaskType = taskType
      end
    end
  end
  
  if bestTaskType and openTasks[bestTaskType] and #openTasks[bestTaskType] > 0 then
    local target = table.remove(openTasks[bestTaskType], 1)
    return self:createTaskFromTypeAndTarget(bestTaskType, target)
  end
  
  return nil
end

---Create a task structure from task type and target
---@param taskType TaskType
---@param target Vec2
---@return table task
function TaskManager:createTaskFromTypeAndTarget(taskType, target)
  return {
    type = taskType,
    target = target,
    priority = 1.0,
    timer = 0,
    isComplete = false
  }
end

---Initialize ECS systems
function TaskManager:initializeECSSystems()
  if self.taskExecutionSystem and self.taskComponentPool then
    return -- Already initialized
  end

  -- Import ECS systems
  local TaskExecutionSystem = require("game.systems.TaskExecutionSystem")
  local TaskComponentPool = require("game.systems.TaskComponentPool")
  local TaskDependencyResolver = require("game.systems.TaskDependencyResolver")

  -- Initialize systems (keep module references for proper self context)
  self.taskExecutionSystem = TaskExecutionSystem
  self.taskComponentPool = TaskComponentPool

  -- Initialize if not already done
  if not TaskExecutionSystem.isInitialized then
    TaskExecutionSystem:init()
  end

  if not TaskComponentPool.componentClasses or not next(TaskComponentPool.componentClasses) then
    TaskComponentPool:init(love.timer.getTime())
  end
  
  -- Set up dependency resolver
  TaskExecutionSystem:setDependencyResolver(TaskDependencyResolver)

  Logger:info("TaskManager: ECS systems initialized")
end

---Create an ECS task component for an entity
---@param taskType TaskType
---@param target any
---@param entity integer
---@param priority number|nil
---@return boolean success
function TaskManager:createECSTask(taskType, target, entity, priority)
  local TaskComponentPool = require("game.systems.TaskComponentPool")
  
  Logger:debug("TaskManager:createECSTask called - taskType: " .. tostring(taskType) .. ", entity: " .. tostring(entity))
  Logger:debug("TaskManager: taskComponentPool: " .. tostring(self.taskComponentPool))
  
  if not self.taskComponentPool then
    Logger:error("TaskManager: Cannot create ECS task - ECS systems not initialized")
    return false
  end

  -- Map TaskType to ComponentType (this will need expansion)
  local componentType
  if taskType == TaskType.MOVETO then
    componentType = ComponentType.MOVEMENT_TASK
  elseif taskType == TaskType.MINE then
    componentType = ComponentType.MINING_TASK
  elseif taskType == TaskType.CONSTRUCT then
    componentType = ComponentType.CONSTRUCTION_TASK
  elseif taskType == TaskType.CLEAN then
    componentType = ComponentType.CLEANING_TASK
  else
    Logger:error("TaskManager: Unsupported task type for ECS: " .. tostring(taskType))
    return false
  end

  Logger:debug("TaskManager: Creating ECS task - taskType: " .. tostring(taskType) .. ", componentType: " .. tostring(componentType))

  -- Get component from pool (call directly on module to preserve self context)
  local taskComponent = TaskComponentPool:acquire(componentType)
  if not taskComponent then
    Logger:error("TaskManager: Failed to acquire task component from pool")
    return false
  end

  Logger:debug("TaskManager: Acquired component from pool")

  -- Initialize component with target
  if taskComponent.setTarget then
    taskComponent:setTarget(target)
  end

  -- Assign task to entity via TaskExecutionSystem
  local success = self.taskExecutionSystem:assignTask(entity, taskComponent, priority)
  Logger:debug("TaskManager: assignTask returned: " .. tostring(success))
  return success
end

---Convert a legacy Task object to an ECS task component using TaskAdapter
---@param legacyTask Task
---@param entity integer
---@return boolean success
function TaskManager:convertLegacyTask(legacyTask, entity)
  -- Use TaskAdapter for conversion
  local TaskAdapter = require("game.adapters.TaskAdapter")
  local component, componentType, error = TaskAdapter:convertToECS(legacyTask, entity)
  
  if not component then
    Logger:error("TaskManager: Failed to convert legacy task - " .. (error or "unknown error"))
    return false
  end

  -- Assign the converted task to the entity via TaskExecutionSystem
  local success = self.taskExecutionSystem:assignTask(entity, component, 1.0)
  if not success then
    -- Release component back to pool if assignment failed
    self.taskComponentPool:release(component, componentType)
    Logger:error("TaskManager: Failed to assign converted task to entity")
    return false
  end

  Logger:debug("TaskManager: Successfully converted and assigned legacy task")
  return true
end

---Assign a task to an entity's TaskQueue (ECS mode)
---@param entityId integer
---@param task any Legacy task or ECS task component
---@return boolean success
function TaskManager:assignTaskToQueue(entityId, task)
  local EntityManager = require("game.systems.EntityManager")
  local taskQueue = EntityManager:getComponent(entityId, ComponentType.TASKQUEUE)
  
  if not taskQueue then
    Logger:error("TaskManager: Entity " .. entityId .. " has no TaskQueue component")
    return false
  end
  
  -- ECS mode: TaskQueue will handle conversion if needed
  taskQueue:push(task)
  Logger:info("TaskManager: Assigned task to ECS TaskQueue for entity " .. entityId)
  return true
end

return TaskManager