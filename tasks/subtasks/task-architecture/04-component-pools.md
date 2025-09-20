# 04 - Component Pools

## Objective
Implement object pooling system for task components to minimize memory allocation overhead and improve performance during high-frequency component creation/destruction.

## Scope
- Create TaskComponentPool system for component reuse
- Implement pool management for all task component types
- Add automatic pool size management and monitoring
- Provide clean allocation/deallocation interface

## Implementation Details

### TaskComponentPool System
```lua
-- game/systems/TaskComponentPool.lua
TaskComponentPool = {
  pools = {
    [ComponentType.MOVEMENT_TASK] = {},
    [ComponentType.MINING_TASK] = {},
    [ComponentType.CONSTRUCTION_TASK] = {},
    [ComponentType.CLEANING_TASK] = {}
  },
  poolSizes = {},      -- Track current pool sizes
  poolStats = {}       -- Performance metrics
}
```

### Core Methods
- `TaskComponentPool:acquire(componentType)` - Get component from pool or create new
- `TaskComponentPool:release(component)` - Return component to pool after reset
- `TaskComponentPool:preAllocate(componentType, count)` - Warm up pools
- `TaskComponentPool:getPoolStats()` - Return allocation metrics
- `TaskComponentPool:cleanup()` - Trim oversized pools

### Component Integration
Each task component needs:
- `Component:reset()` - Clear data for pool reuse
- `Component:isPoolable()` - Check if safe to pool
- `Component.newFromPool()` - Factory method using pool

### Pool Management Strategy
- Initial pool size: 10 components per type
- Growth strategy: Double when empty, shrink by half when >50 unused
- Maximum pool size: 100 components per type
- Cleanup frequency: Every 60 seconds of game time

## Files to Create
- `game/systems/TaskComponentPool.lua` - Main pool implementation

## Files to Modify
- `game/components/TaskComponent.lua` - Add reset() and pool methods
- `game/components/MovementTask.lua` - Add pool integration
- `game/components/MiningTask.lua` - Add pool integration
- `game/components/ConstructionTask.lua` - Add pool integration
- `game/components/CleaningTask.lua` - Add pool integration

## Tests
Create test file `testing/__tests__/task_component_pool.lua`:
- Test component acquisition and release
- Test pool growth and shrinking behavior
- Test component reset functionality
- Test pool statistics accuracy
- Benchmark allocation performance vs direct creation

## Acceptance Criteria
- [ ] TaskComponentPool manages all task component types
- [ ] Components are properly reset when returned to pool
- [ ] Pool automatically manages size based on usage patterns
- [ ] Statistics tracking works correctly
- [ ] Performance improvement measurable (>50% allocation speedup)
- [ ] All tests pass
- [ ] Code follows project style guidelines

## Dependencies
- All task component classes (subtasks 01-03)
- EntityManager for component type management
- Timer system for cleanup scheduling

## Estimated Time
60 minutes

## Notes
Focus on correctness over premature optimization. Ensure components are completely reset when pooled to avoid state pollution. Pool statistics will be crucial for tuning performance in production.