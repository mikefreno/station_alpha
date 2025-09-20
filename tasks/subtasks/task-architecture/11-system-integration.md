# 11 - System Integration

## Objective
Ensure the new task architecture integrates seamlessly with existing systems (Position, Render, Input, EntityManager) and verify all game systems work correctly with the component-based task approach.

## Scope
- Test integration with existing Position system
- Verify Render system compatibility with new components
- Ensure Input system can trigger new task assignments
- Validate EntityManager handles new component types
- Test complete game loop with new architecture

## Implementation Details

### Position System Integration
```lua
-- Ensure Position system works with MovementTask
function PositionSystem:update(dt)
  -- Process regular position updates
  -- MovementSystem handles MovementTask components separately
  -- Ensure no conflicts between systems
end
```

### Render System Compatibility
- Verify new task components don't interfere with rendering
- Test task progress visualization (if implemented)
- Ensure entity state changes render correctly

### Input System Integration
```lua
-- Update input handlers for new task assignment
function InputSystem:onRightClick(position)
  local selectedEntities = self:getSelectedEntities()
  for _, entity in ipairs(selectedEntities) do
    -- Use new task assignment through TaskManager
    TaskManager:assignTaskToEntity(entity, TaskType.MOVETO, position)
  end
end
```

### EntityManager Updates
- Ensure EntityManager handles new component types
- Test component lifecycle with pooled components
- Verify entity destruction cleans up task components

### Complete Integration Test
```lua
-- Full game loop test
function testCompleteTaskFlow()
  -- 1. Create entity with Position, Velocity, TaskQueue
  -- 2. Assign mining task via TaskManager
  -- 3. Verify MovementTask inserted by dependency resolver
  -- 4. Process movement via MovementSystem
  -- 5. Process mining via MiningProcessor
  -- 6. Verify task completion and cleanup
end
```

## Files to Create
- None (integration testing)

## Files to Modify
- `game/main.lua` - Update to include TaskExecutionSystem in main loop
- `game/systems/EntityManager.lua` - Ensure component type support
- Any input handling files - Update task assignment calls

## Tests
Create test file `testing/__tests__/system_integration.lua`:
- Test complete task lifecycle with all systems
- Test system update order and dependencies
- Test input-triggered task assignment
- Test rendering with active tasks
- Performance test with all systems running

## Acceptance Criteria
- [ ] Position system works alongside MovementSystem
- [ ] Render system displays entities with active tasks correctly
- [ ] Input system can assign tasks using new architecture
- [ ] EntityManager properly manages new component types
- [ ] Complete game loop functions without issues
- [ ] No performance regressions in existing systems
- [ ] All tests pass
- [ ] Code follows project style guidelines

## Dependencies
- All previous subtasks (01-10)
- Existing Position, Render, Input systems
- EntityManager
- Main game loop

## Estimated Time
45 minutes

## Notes
This integration phase is critical for ensuring the new architecture doesn't break existing functionality. Focus on thorough testing of system interactions. Pay special attention to the order of system updates to ensure proper functionality.