# 07 - Movement System

## Objective
Implement the MovementSystem that batch processes all MovementTask components, updating entity positions along paths and handling movement completion with integration to existing Position and Velocity systems.

## Scope
- Create batch movement processing system
- Integrate with existing Position and Velocity components  
- Handle path following and waypoint advancement
- Optimize for performance with large numbers of moving entities

## Implementation Details

### MovementSystem Core
```lua
-- game/systems/MovementSystem.lua
MovementSystem = {
  spatialIndex = nil,           -- Optional spatial optimization
  movementSpeed = 1.0,          -- Default movement speed (tiles/second)
  waypointThreshold = 0.1       -- Distance to consider waypoint reached
}
```

### Batch Processing Method
```lua
function MovementSystem:processBatch(movingEntities, dt)
  for _, entity in ipairs(movingEntities) do
    local movementTask = EntityManager:getComponent(entity, ComponentType.MOVEMENT_TASK)
    local position = EntityManager:getComponent(entity, ComponentType.POSITION)
    local velocity = EntityManager:getComponent(entity, ComponentType.VELOCITY)
    
    if movementTask and position then
      self:updateMovement(entity, movementTask, position, velocity, dt)
    end
  end
end
```

### Movement Logic
- Calculate direction to current waypoint
- Update velocity based on movement speed and direction
- Update position using velocity and delta time
- Check if waypoint reached and advance to next
- Remove MovementTask when destination reached

### Integration with Position System
- Works alongside existing Position system
- Uses Velocity component for smooth movement
- Respects existing movement speed stats from entities

### Performance Optimizations
- Batch process entities with same movement characteristics
- Early exit for stationary entities
- Spatial indexing for collision detection (if needed)

## Files to Create
- `game/systems/MovementSystem.lua` - Movement processing system

## Files to Modify
- None (new system, but integrates with existing Position/Velocity)

## Tests
Create test file `testing/__tests__/movement_system.lua`:
- Test batch processing with multiple entities
- Test waypoint advancement along paths
- Test destination detection and task removal
- Test integration with Position/Velocity components
- Performance test with 100+ moving entities

## Acceptance Criteria
- [ ] Efficiently processes batches of moving entities
- [ ] Correctly advances entities along paths
- [ ] Integrates seamlessly with Position/Velocity systems
- [ ] Removes MovementTask when destination reached
- [ ] Performance acceptable with large entity counts
- [ ] All tests pass
- [ ] Code follows project style guidelines

## Dependencies
- MovementTask component (subtask 02)
- Existing Position and Velocity components
- EntityManager for component access
- Vec2 utility for vector math

## Estimated Time
50 minutes

## Notes
This system must be highly optimized since it runs every frame for potentially many entities. Focus on cache-friendly data access patterns and minimal per-entity overhead. Integration with existing systems is critical.