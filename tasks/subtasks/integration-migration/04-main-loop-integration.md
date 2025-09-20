# Subtask 04: Main Loop Integration

## Overview
Integrate the TaskExecutionSystem into the main game loop alongside the existing TaskManager, enabling seamless transition between legacy and ECS task processing modes.

## Current State Analysis
- `game/main.lua:69` currently calls `TaskManager:update(dt)`
- TaskExecutionSystem exists but is not integrated into game loop
- Need to coordinate both systems during migration period

## Integration Strategy

### 1. Main Loop Enhancement
```lua
-- game/main.lua update function enhancement
function love.update(dt)
    -- Existing systems
    TaskManager:update(dt)
    
    -- New ECS task processing
    if TaskManager:isECSModeEnabled() then
        TaskExecutionSystem:update(dt)
        TaskDependencyResolver:update()
        MovementSystem:update(dt)
    end
end
```

### 2. System Coordination
- TaskManager controls which systems are active based on mode
- Prevents duplicate processing of same entities
- Ensures proper initialization order

### 3. Performance Considerations
- ECS systems only run when entities exist to process
- Early exit mechanisms for empty component pools
- Minimize overhead during legacy-only operation

## Implementation Details

### Files to Modify
- `game/main.lua` - Add ECS system calls
- `game/systems/TaskManager.lua` - Add ECS mode control
- `game/systems/TaskExecutionSystem.lua` - Add early exit optimization

### Integration Points
1. **System Initialization**: Ensure all ECS systems are properly initialized
2. **Update Order**: TaskDependencyResolver → TaskExecutionSystem → MovementSystem
3. **Mode Switching**: Runtime switching between legacy/ECS/hybrid modes
4. **Error Handling**: Graceful fallback to legacy mode on ECS errors

## Testing Requirements
- Verify no performance regression in legacy mode
- Test smooth transitions between modes
- Validate all existing functionality preserved
- Benchmark ECS mode performance improvements

## Success Criteria
- [ ] ECS systems integrated into main loop
- [ ] Mode switching works without game interruption
- [ ] Performance meets or exceeds legacy baseline
- [ ] All existing task functionality preserved
- [ ] Clean separation of concerns between systems

## Dependencies
- Requires: Subtasks 01-03 (TaskManager bridge, TaskAdapter, TaskQueue integration)
- Enables: Subtasks 05-08 (legacy phaseout, testing, optimization)

## Estimated Effort
**Medium** - Core integration work with careful coordination required