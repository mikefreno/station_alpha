# 09 - Task Manager Migration

## Objective
Migrate the existing TaskManager to work with the new component-based task system, updating task assignment logic and integration with the new TaskExecutionSystem.

## Scope
- Update TaskManager to use new task components instead of Task objects
- Integrate with TaskExecutionSystem for task processing
- Migrate task assignment and scheduling logic
- Maintain compatibility with existing Schedule component

## Implementation Details

### Updated TaskManager Interface
```lua
-- Updated game/systems/TaskManager.lua
TaskManager = {
  openTasks = {},               -- Available tasks by type
  taskExecutionSystem = nil,    -- Reference to TaskExecutionSystem
  componentPool = nil           -- Reference to TaskComponentPool
}
```

### Migration Changes
- Replace `Task.new()` calls with component creation via pools
- Update task assignment to use `TaskExecutionSystem:assignTask()`
- Convert task type enums to component types
- Maintain existing integration with Schedule component

### Task Assignment Updates
```lua
function TaskManager:assignTaskToEntity(entityId, taskType, target)
  local taskComponent
  
  -- Create appropriate task component
  if taskType == TaskType.MINE then
    taskComponent = TaskComponentPool:acquire(ComponentType.MINING_TASK)
    taskComponent:initialize(target, priority, requiredDistance)
  elseif taskType == TaskType.CONSTRUCT then
    taskComponent = TaskComponentPool:acquire(ComponentType.CONSTRUCTION_TASK)
    -- ... component initialization
  end
  
  -- Assign via TaskExecutionSystem
  self.taskExecutionSystem:assignTask(entityId, taskComponent)
end
```

### Schedule Integration
- Maintain existing Schedule:selectNextTask() interface
- Convert selected tasks to new component format
- Preserve task priority and weighting logic

### Legacy Task Conversion
- Map old TaskType enums to new ComponentType enums
- Convert task data structures to component format
- Handle existing task queue migration

## Files to Create
- None (migration of existing file)

## Files to Modify
- `game/systems/TaskManager.lua` - Major refactoring for component system
- `game/components/Schedule.lua` - Update to work with new task types

## Tests
Create test file `testing/__tests__/task_manager_migration.lua`:
- Test task assignment with new component system
- Test integration with TaskExecutionSystem
- Test Schedule component compatibility
- Test conversion from legacy task types
- Performance comparison with old system

## Acceptance Criteria
- [ ] TaskManager works with new component-based tasks
- [ ] Task assignment integrates with TaskExecutionSystem
- [ ] Schedule component still functions correctly
- [ ] Performance is equal or better than legacy system
- [ ] All existing task assignment flows work
- [ ] All tests pass
- [ ] Code follows project style guidelines

## Dependencies
- TaskExecutionSystem (subtask 05)
- TaskComponentPool (subtask 04)
- All task components (subtasks 01-03)
- Existing Schedule component

## Estimated Time
55 minutes

## Notes
This migration must maintain all existing functionality while switching to the new architecture. Careful testing is essential to ensure no regressions in task assignment behavior. Consider keeping legacy methods temporarily for gradual migration.