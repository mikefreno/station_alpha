# 10 - Legacy System Migration

## Objective
Replace the existing Task.lua and TaskQueue components with the new component-based architecture, ensuring all current functionality is preserved while gaining the performance benefits of the new system.

## Scope
- Phase out the old Task.lua class completely
- Update TaskQueue to work with new task components
- Migrate all references to old task system
- Ensure backward compatibility during transition

## Implementation Details

### TaskQueue Migration
```lua
-- Updated game/components/TaskQueue.lua
TaskQueue = {
  activeTaskComponents = {},    -- Current active task components
  queuedTasks = {},            -- Pending task assignments (simplified)
  maxConcurrentTasks = 1       -- Number of simultaneous tasks
}
```

### Task.lua Replacement Strategy
1. **Phase 1**: Add compatibility layer to TaskQueue for new components
2. **Phase 2**: Update all task creation to use new components
3. **Phase 3**: Remove old Task.lua entirely

### Component Integration
- Replace `Task.new()` calls with component creation
- Update task performance logic to use new processors
- Migrate task completion handling to new system

### MoveTo Integration
```lua
-- Update MoveTo component to work with MovementTask
function TaskQueue:addMovementTask(targetPosition)
  local movementTask = TaskComponentPool:acquire(ComponentType.MOVEMENT_TASK)
  movementTask:initialize(targetPosition, 0.5, 1.0)
  
  EntityManager:addComponent(self.entityId, ComponentType.MOVEMENT_TASK, movementTask)
end
```

### Migration Checklist
- [ ] Replace all Task.new() calls
- [ ] Update task completion detection
- [ ] Migrate task queuing logic
- [ ] Remove Task.lua file
- [ ] Update all imports/requires

## Files to Create
- None (migration of existing files)

## Files to Modify
- `game/components/TaskQueue.lua` - Major refactoring
- `game/components/Task.lua` - Delete after migration
- Any files that import Task.lua - Update imports

## Tests
Create test file `testing/__tests__/legacy_migration.lua`:
- Test TaskQueue with new components
- Test task creation and assignment flows
- Test MoveTo component integration
- Verify all old functionality still works
- Performance comparison tests

## Acceptance Criteria
- [ ] TaskQueue works with new task components
- [ ] All task creation flows updated to new system
- [ ] MoveTo integration preserved and enhanced
- [ ] No references to old Task.lua remain
- [ ] All existing game functionality preserved
- [ ] Performance improved over legacy system
- [ ] All tests pass
- [ ] Code follows project style guidelines

## Dependencies
- All new task components (subtasks 01-03)
- TaskComponentPool (subtask 04)
- TaskExecutionSystem (subtask 05)
- Existing MoveTo component

## Estimated Time
60 minutes

## Notes
This is a critical migration that affects core game functionality. Thorough testing is essential. Consider implementing feature flags to toggle between old and new systems during development to enable safe rollback if issues arise.