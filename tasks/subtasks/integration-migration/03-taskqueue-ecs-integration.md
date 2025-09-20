# 03. TaskQueue ECS Integration

## Objective
Modify TaskQueue to seamlessly work with both legacy Task objects and new ECS task components, providing a unified interface during the migration period.

## Overview
TaskQueue.lua currently manages per-entity task execution using legacy Task objects. This subtask enhances TaskQueue to support ECS task components while maintaining backward compatibility with existing task management patterns.

## Current State Analysis
- **TaskQueue.lua**: Manages queue table, currentTask field, pop/push operations
- **Current update logic**: Calls task:perform(dt) and checks isComplete flag
- **Task creation**: Receives Task objects via push() method
- **Entity ownership**: Each TaskQueue has an ownerId field

## Requirements

### 1. Hybrid Task Support
```lua
-- Enhanced TaskQueue to support both task types
---@class TaskQueue
---@field ownerId integer
---@field queue table<integer, Task|ECSTaskComponent>  -- Mixed task types
---@field currentTask Task|ECSTaskComponent|nil
---@field ecsMode boolean -- Flag for ECS component handling
```

### 2. Task Type Detection
```lua
-- Methods to identify task types
function TaskQueue:isECSComponent(item)
function TaskQueue:isLegacyTask(item) 
function TaskQueue:getTaskType(item)
```

### 3. Unified Task Interface
```lua
-- Wrapper methods for common operations
function TaskQueue:performTask(task, dt)
function TaskQueue:isTaskComplete(task)
function TaskQueue:getTaskTarget(task)
function TaskQueue:setTaskComplete(task)
```

## Implementation Steps

### Step 1: Enhance TaskQueue Structure
```lua
-- Add new fields to TaskQueue.new()
function TaskQueue.new(ownerId)
  local self = setmetatable({}, { __index = TaskQueue })
  self.ownerId = ownerId
  self.queue = {}
  self.currentTask = nil
  self.ecsMode = false -- Default to legacy mode
  self.taskAdapter = require("game.adapters.TaskAdapter")
  return self
end
```

### Step 2: Add Task Type Detection
```lua
function TaskQueue:isECSComponent(item)
  return type(item) == "table" and item.componentType ~= nil
end

function TaskQueue:isLegacyTask(item)
  return type(item) == "table" and item.type ~= nil and item.perform ~= nil
end

function TaskQueue:getTaskType(item)
  if self:isECSComponent(item) then
    return "ECS"
  elseif self:isLegacyTask(item) then
    return "LEGACY"
  else
    return "UNKNOWN"
  end
end
```

### Step 3: Implement Unified Task Interface
```lua
function TaskQueue:performTask(task, dt)
  local taskType = self:getTaskType(task)
  
  if taskType == "LEGACY" then
    task:perform(dt)
  elseif taskType == "ECS" then
    -- ECS components are processed by TaskExecutionSystem
    -- Just update timer here for compatibility
    if task.updateTimer then
      task:updateTimer(dt)
    end
  else
    Logger:error("Unknown task type in TaskQueue:performTask")
  end
end

function TaskQueue:isTaskComplete(task)
  local taskType = self:getTaskType(task)
  
  if taskType == "LEGACY" then
    return task.isComplete
  elseif taskType == "ECS" then
    return task:isComplete()
  else
    return true -- Treat unknown tasks as complete
  end
end
```

### Step 4: Update Core TaskQueue Methods
```lua
function TaskQueue:update(dt)
  if self.currentTask then
    self:performTask(self.currentTask, dt)
    if not self:isTaskComplete(self.currentTask) then
      return
    end
    
    -- Handle task completion cleanup
    self:handleTaskCompletion(self.currentTask)
  end

  if #self.queue == 0 then
    return
  end

  self.currentTask = self:pop()
end

function TaskQueue:handleTaskCompletion(task)
  local taskType = self:getTaskType(task)
  
  if taskType == "ECS" then
    -- Return ECS component to pool
    local pool = require("game.systems.TaskComponentPool")
    pool:release(task, task.componentType, self.ownerId)
  end
  
  -- Legacy tasks are garbage collected automatically
end
```

### Step 5: Add ECS Mode Support
```lua
function TaskQueue:enableECSMode()
  self.ecsMode = true
end

function TaskQueue:disableECSMode()
  self.ecsMode = false
end

-- Enhanced push method
function TaskQueue:push(task)
  -- Convert legacy tasks to ECS when in ECS mode
  if self.ecsMode and self:isLegacyTask(task) then
    local component, componentType = self.taskAdapter:convertToECS(task, self.ownerId)
    if component then
      EntityManager:addComponent(self.ownerId, componentType, component)
      table.insert(self.queue, component)
    else
      -- Fallback to legacy task
      table.insert(self.queue, task)
    end
  else
    table.insert(self.queue, task)
  end
end
```

### Step 6: Migration Helper Methods
```lua
-- Convert entire queue to ECS components
function TaskQueue:convertToECS()
  local newQueue = {}
  
  for i, task in ipairs(self.queue) do
    if self:isLegacyTask(task) then
      local component, componentType = self.taskAdapter:convertToECS(task, self.ownerId)
      if component then
        EntityManager:addComponent(self.ownerId, componentType, component)
        table.insert(newQueue, component)
      else
        table.insert(newQueue, task) -- Keep as legacy
      end
    else
      table.insert(newQueue, task) -- Already ECS or unknown
    end
  end
  
  self.queue = newQueue
  self.ecsMode = true
end

-- Convert current task if needed
function TaskQueue:convertCurrentTask()
  if self.currentTask and self:isLegacyTask(self.currentTask) then
    local component, componentType = self.taskAdapter:convertToECS(self.currentTask, self.ownerId)
    if component then
      EntityManager:addComponent(self.ownerId, componentType, component)
      self.currentTask = component
    end
  end
end
```

## Testing Requirements

### Unit Tests
- Test task type detection accuracy
- Verify unified interface operations
- Test queue operations with mixed task types
- Validate ECS mode conversion

### Integration Tests
- Test TaskQueue with TaskManager in both modes
- Verify task execution with mixed task types
- Test conversion between legacy and ECS tasks

## Acceptance Criteria
- [ ] TaskQueue works with legacy Task objects (no regression)
- [ ] TaskQueue supports ECS task components
- [ ] Mixed task queues function correctly
- [ ] ECS mode conversion works seamlessly
- [ ] Task completion cleanup prevents memory leaks
- [ ] Performance impact minimal (< 3% overhead)

## Edge Cases to Handle
- **Empty queues**: Handle transition between modes with no tasks
- **Invalid tasks**: Gracefully handle corrupted or unknown task objects
- **Conversion failures**: Fallback to legacy behavior when ECS conversion fails
- **Memory management**: Proper cleanup of ECS components

## Files to Modify
- `game/components/TaskQueue.lua`

## Dependencies
- TaskAdapter implementation (subtask 02)
- TaskComponentPool operational
- EntityManager component support

## Estimated Effort
**Medium** - Requires careful interface design and thorough testing