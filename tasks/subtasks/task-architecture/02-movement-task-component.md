# 02 - Movement Task Component

## Objective
Implement the MovementTask component as a primitive task that handles entity movement with pathfinding integration. This component serves as a dependency for other tasks that require positioning.

## Scope
- Create MovementTask component extending TaskComponent
- Implement path-following logic with waypoint management
- Add movement speed modulation capability
- Integrate with existing PathFinder system

## Implementation Details

### MovementTask Component
```lua
-- game/components/MovementTask.lua
MovementTask = TaskComponent:extend()
MovementTask = {
  path = Vec2[],                 -- Current path to follow
  currentWaypoint = number,      -- Index in path array (0-based)
  targetPosition = Vec2,         -- Final destination
  movementSpeed = number         -- Movement rate modifier (default 1.0)
}
```

### Core Methods
- `MovementTask.new(targetPosition, requiredDistance, movementSpeed)` - Constructor
- `MovementTask:setPath(path)` - Updates path and resets waypoint index
- `MovementTask:getCurrentTarget()` - Returns current waypoint position
- `MovementTask:advanceWaypoint()` - Moves to next waypoint
- `MovementTask:isAtDestination(currentPos)` - Checks if close enough to target
- `MovementTask:getProgress()` - Returns path completion percentage

### Integration Points
- Uses existing PathFinder for path generation
- Works with Position component for current entity location
- Integrates with Velocity component for movement

## Files to Create
- `game/components/MovementTask.lua` - Movement task implementation

## Files to Modify
- `game/utils/enums.lua` - Ensure MOVEMENT_TASK enum exists (from subtask 01)

## Tests
Create test file `testing/__tests__/movement_task.lua`:
- Test movement task creation with valid path
- Test waypoint advancement logic
- Test destination detection with various distances
- Test progress calculation along path
- Test invalid path handling

## Acceptance Criteria
- [ ] MovementTask component extends TaskComponent properly
- [ ] Path following logic correctly advances through waypoints
- [ ] Distance calculations work with configurable required distance
- [ ] Progress reporting accurately reflects path completion
- [ ] All tests pass
- [ ] Code follows project style guidelines

## Dependencies
- TaskComponent base class (from subtask 01)
- Vec2 utility class
- Existing PathFinder system integration
- Position and Velocity components

## Estimated Time
50 minutes

## Notes
This component is critical as it's used by all other tasks that require movement. The implementation should be highly optimized since it will be used frequently in batch processing.