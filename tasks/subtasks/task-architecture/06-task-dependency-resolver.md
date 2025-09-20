# 06 - Task Dependency Resolver

## Objective
Implement the TaskDependencyResolver system that automatically inserts MovementTask components when entities need to move to perform other tasks, handling pathfinding and dependency management.

## Scope
- Create dependency resolution logic for movement requirements
- Integrate with existing PathFinder for route calculation
- Implement proximity detection and distance validation
- Handle movement task insertion and cleanup

## Implementation Details

### TaskDependencyResolver Core
```lua
-- game/systems/TaskDependencyResolver.lua
TaskDependencyResolver = {
  pathfinder = nil,             -- PathFinder instance
  proximityCache = {},          -- Cache for distance calculations
  cacheTimeout = 0.5            -- Cache validity in seconds
}
```

### Core Methods
- `TaskDependencyResolver:checkMovementNeeded(entity, taskComponent)` - Check if movement required
- `TaskDependencyResolver:insertMovementTask(entity, targetPos, requiredDistance)` - Add movement task
- `TaskDependencyResolver:removeCompletedDependencies(entity)` - Clean up finished movement
- `TaskDependencyResolver:isInRange(entity, target, requiredDistance)` - Distance validation
- `TaskDependencyResolver:calculatePath(fromPos, toPos)` - Generate path using PathFinder

### Dependency Logic
```lua
function TaskDependencyResolver:checkMovementNeeded(entity, taskComponent)
  local entityPos = EntityManager:getComponent(entity, ComponentType.POSITION)
  local targetPos = self:getTargetPosition(taskComponent.target)
  
  if not self:isInRange(entityPos, targetPos, taskComponent.requiredDistance) then
    -- Entity needs to move - insert MovementTask
    return self:insertMovementTask(entity, targetPos, taskComponent.requiredDistance)
  end
  
  return false -- No movement needed
end
```

### PathFinder Integration
- Use existing PathFinder system for route calculation
- Handle pathfinding failures gracefully
- Cache paths for performance when multiple entities target same location

### Performance Optimizations
- Cache proximity calculations to avoid repeated distance checks
- Batch pathfinding requests when possible
- Reuse paths for nearby targets

## Files to Create
- `game/systems/TaskDependencyResolver.lua` - Main resolver implementation

## Files to Modify
- None (new system)

## Tests
Create test file `testing/__tests__/task_dependency_resolver.lua`:
- Test movement requirement detection
- Test path insertion with valid targets
- Test proximity detection with various distances
- Test pathfinding integration
- Test performance with cached calculations

## Acceptance Criteria
- [x] Correctly detects when entities need to move for tasks
- [x] Integrates with PathFinder for route calculation
- [x] Handles pathfinding failures without crashing
- [x] Performance is acceptable with proximity caching
- [x] Movement tasks are inserted/removed correctly
- [x] All tests pass
- [x] Code follows project style guidelines

## Dependencies
- Existing PathFinder system
- MovementTask component (subtask 02)
- Position component system
- EntityManager for component access

## Estimated Time
50 minutes

## Notes
This system is critical for the seamless operation of the task architecture. It must be robust in handling edge cases like unreachable targets or pathfinding failures. Focus on performance since this runs frequently.