# 02. Legacy Task to ECS Component Adapter

## Objective
Build an adapter system that converts legacy Task objects to ECS task components, enabling seamless transition between the old and new task systems.

## Overview
During the migration phase, we need to support both legacy Task objects and new ECS task components. This adapter creates a translation layer that converts existing Task.lua instances into their equivalent ECS components while preserving all functionality.

## Current State Analysis
- **Task.lua**: Legacy task class with hardcoded perform() logic
- **TaskType enum**: Defines MOVETO, MINE, CONSTRUCTION, CLEANING, etc.
- **Task data**: Contains type, target, performer, isComplete, timer fields
- **Legacy task creation**: `Task.new(TaskType.MINE, target)`

## Requirements

### 1. Task Adapter Interface
```lua
-- New file: game/adapters/TaskAdapter.lua
local TaskAdapter = {}

-- Convert legacy Task to ECS component
function TaskAdapter:convertToECS(legacyTask, entityId)

-- Convert ECS component back to legacy Task (for compatibility)
function TaskAdapter:convertToLegacy(component, componentType, entityId)

-- Check if conversion is possible
function TaskAdapter:canConvert(legacyTask)
```

### 2. Task Type Mapping
```lua
-- Map legacy TaskType to ECS ComponentType
local TASK_TYPE_MAPPING = {
  [TaskType.MOVETO] = ComponentType.MOVEMENT_TASK,
  [TaskType.MINE] = ComponentType.MINING_TASK,
  [TaskType.CONSTRUCTION] = ComponentType.CONSTRUCTION_TASK,
  [TaskType.CLEANING] = ComponentType.CLEANING_TASK,
}
```

### 3. Data Transformation Rules
- **Target handling**: Convert integer targets to entity IDs, Vec2 targets to positions
- **Timer preservation**: Maintain existing task progress
- **State mapping**: Map isComplete flag to component state
- **Performer assignment**: Ensure proper entity ownership

## Implementation Steps

### Step 1: Create TaskAdapter Module
- Create `game/adapters/TaskAdapter.lua`
- Define task type mapping constants
- Implement conversion validation logic

### Step 2: Implement convertToECS Method
```lua
function TaskAdapter:convertToECS(legacyTask, entityId)
  local componentType = TASK_TYPE_MAPPING[legacyTask.type]
  if not componentType then
    Logger:error("Cannot convert task type: " .. legacyTask.type)
    return nil
  end
  
  local component = TaskComponentPool:acquire(componentType, entityId)
  if not component then
    return nil
  end
  
  -- Copy legacy task data to ECS component
  component:setTarget(legacyTask.target)
  component:setTimer(legacyTask.timer)
  component:setEntityId(entityId)
  
  if legacyTask.isComplete then
    component:markComplete()
  end
  
  return component, componentType
end
```

### Step 3: Implement convertToLegacy Method  
```lua
function TaskAdapter:convertToLegacy(component, componentType, entityId)
  local taskType = self:getTaskTypeFromComponent(componentType)
  if not taskType then
    return nil
  end
  
  local legacyTask = Task.new(taskType, component:getTarget())
  legacyTask.performer = entityId
  legacyTask.timer = component:getTimer()
  legacyTask.isComplete = component:isComplete()
  
  return legacyTask
end
```

### Step 4: Add Validation and Error Handling
- Validate task data before conversion
- Handle unsupported task types gracefully
- Log conversion failures for debugging
- Provide fallback mechanisms

### Step 5: Integration with TaskManager Bridge
```lua
-- In TaskManager.lua
local TaskAdapter = require("game.adapters.TaskAdapter")

function TaskManager:convertLegacyTask(legacyTask, entityId)
  local component, componentType = TaskAdapter:convertToECS(legacyTask, entityId)
  if component then
    EntityManager:addComponent(entityId, componentType, component)
    return true
  end
  return false
end
```

### Step 6: Backward Compatibility Layer
- Support reading ECS components as legacy tasks
- Ensure TaskQueue can work with both types
- Maintain existing API contracts

## Testing Requirements

### Unit Tests
- Test conversion of each task type
- Verify data preservation during conversion
- Test edge cases (invalid tasks, missing data)
- Validate bidirectional conversion accuracy

### Integration Tests
- Test TaskQueue with converted tasks
- Verify task execution with adapted components
- Test mixed legacy/ECS task scenarios

## Acceptance Criteria
- [ ] All legacy TaskType values can be converted to ECS components
- [ ] Converted tasks maintain all original data (target, timer, state)
- [ ] Bidirectional conversion preserves data integrity
- [ ] Unsupported tasks are handled gracefully with clear error messages
- [ ] Performance impact is minimal (< 5% overhead)
- [ ] Existing legacy code continues to work unchanged

## Edge Cases to Handle
- **Invalid targets**: Handle deleted entities or invalid positions
- **Partial task data**: Tasks with missing or corrupted fields
- **Timer edge cases**: Negative timers, very large values
- **State inconsistencies**: Tasks marked complete but with remaining work

## Files to Create
- `game/adapters/TaskAdapter.lua`

## Files to Modify
- `game/systems/TaskManager.lua` (add conversion methods)
- `game/components/TaskQueue.lua` (add adapter support)
- `game/utils/enums.lua` (ensure task type consistency)

## Dependencies
- TaskComponentPool fully implemented
- All ECS task components available
- Component type mapping established

## Estimated Effort
**Medium** - Requires careful data mapping and extensive testing