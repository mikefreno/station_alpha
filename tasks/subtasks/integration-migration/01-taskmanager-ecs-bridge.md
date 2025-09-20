# 01. TaskManager ECS Bridge

## Objective
Create a compatibility bridge between the legacy TaskManager and new ECS systems to enable gradual migration without breaking existing functionality.

## Overview
The current TaskManager.lua serves as the central hub for task distribution and management. This subtask creates a bridge layer that allows the TaskManager to work with both legacy Task objects and new ECS task components during the transition period.

## Current State Analysis
- **TaskManager.lua**: Manages openTasks table, iterates entities with TASKQUEUE components
- **Main game loop**: Calls TaskManager:update(dt) at line 69
- **Task creation**: Uses legacy Task.new() constructor
- **Task assignment**: Via TaskQueue:push() method

## Requirements

### 1. ECS Integration Layer
```lua
-- Add to TaskManager.lua
local TaskExecutionSystem = require("game.systems.TaskExecutionSystem")
local TaskComponentPool = require("game.systems.TaskComponentPool")

-- New fields for TaskManager
self.ecsMode = false -- Toggle between legacy and ECS mode  
self.taskExecutionSystem = nil
self.taskPool = nil
```

### 2. Dual-Mode Operation
- **Legacy Mode**: Existing TaskManager behavior (default)
- **ECS Mode**: Delegate task processing to TaskExecutionSystem
- **Hybrid Mode**: Support both simultaneously during migration

### 3. ECS Task Creation Methods
```lua
-- New methods to add to TaskManager
function TaskManager:createECSTask(taskType, target, entity)
function TaskManager:convertLegacyTask(legacyTask, entity) 
function TaskManager:enableECSMode()
function TaskManager:disableECSMode()
```

## Implementation Steps

### Step 1: Add ECS System Integration
- Import TaskExecutionSystem and TaskComponentPool
- Add new fields to TaskManager constructor
- Initialize ECS systems when ECS mode is enabled

### Step 2: Create Mode Toggle Functions
- `enableECSMode()`: Initialize ECS systems, set ecsMode flag
- `disableECSMode()`: Clean up ECS systems, revert to legacy
- `isECSMode()`: Check current operation mode

### Step 3: Modify update() Method  
```lua
function TaskManager:update(dt)
  if self.ecsMode then
    self.taskExecutionSystem:update(dt)
  else
    -- Existing legacy update logic
  end
  
  -- Handle entity task assignment (works for both modes)
  self:assignTasksToIdleEntities(dt)
end
```

### Step 4: Task Creation Bridge Methods
- `createECSTask()`: Create new ECS task components using TaskComponentPool
- `convertLegacyTask()`: Convert existing Task objects to ECS components
- Maintain backward compatibility for existing task creation calls

### Step 5: TaskQueue Integration
- Modify TaskQueue to detect ECS mode
- Add methods to work with ECS task components
- Preserve existing interface for legacy mode

## Testing Requirements

### Unit Tests
- Test mode switching functionality
- Verify task creation in both modes
- Test conversion between legacy and ECS tasks

### Integration Tests  
- Game startup with ECS mode enabled/disabled
- Task assignment and execution in both modes
- Performance comparison between modes

## Acceptance Criteria
- [ ] TaskManager can operate in legacy mode (no behavioral changes)
- [ ] TaskManager can operate in ECS mode using new systems
- [ ] Mode switching works without breaking existing tasks
- [ ] Task creation works in both modes
- [ ] No performance regression in legacy mode
- [ ] ECS mode shows measurable performance improvement

## Dependencies
- TaskExecutionSystem fully implemented
- TaskComponentPool operational  
- All task processors registered

## Files to Modify
- `game/systems/TaskManager.lua`
- `game/components/TaskQueue.lua`
- `game/main.lua` (for mode initialization)

## Estimated Effort
**Medium** - Requires careful integration without breaking existing systems