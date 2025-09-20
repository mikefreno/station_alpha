# 05 - Task Execution System

## Objective
Implement the central TaskExecutionSystem that coordinates all task processing, manages task lifecycle, and orchestrates batch processing across different task types.

## Scope
- Create the main TaskExecutionSystem that runs each frame
- Implement task lifecycle management (creation, processing, completion)
- Add task priority handling and processing order
- Integrate with dependency resolution and batch processing

## Implementation Details

### TaskExecutionSystem Core
```lua
-- game/systems/TaskExecutionSystem.lua
TaskExecutionSystem = {
  processors = {},              -- Registered task processors
  dependencyResolver = nil,     -- TaskDependencyResolver instance
  processingOrder = {},         -- Order of task type processing
  statistics = {}               -- Performance tracking
}
```

### Core Methods
- `TaskExecutionSystem:init()` - Initialize system and register processors
- `TaskExecutionSystem:update(dt)` - Main update loop for task processing
- `TaskExecutionSystem:registerProcessor(componentType, processor)` - Add task processor
- `TaskExecutionSystem:assignTask(entityId, taskComponent)` - Assign new task to entity
- `TaskExecutionSystem:removeCompletedTasks()` - Clean up finished tasks

### Processing Flow
```lua
function TaskExecutionSystem:update(dt)
  -- 1. Dependency Resolution Phase
  self:resolveDependencies()
  
  -- 2. Batch Processing Phase (movement first, then others)
  self:processMovement(dt)
  self:processActionTasks(dt)
  
  -- 3. Completion Cleanup Phase
  self:removeCompletedTasks()
  self:updateStatistics(dt)
end
```

### Task Assignment Integration
- Works with TaskManager to assign new tasks
- Handles task queuing and priority scheduling
- Manages task component creation via pools

### Performance Monitoring
- Track processing time per task type
- Monitor entity count per task type
- Measure completion rates and task throughput

## Files to Create
- `game/systems/TaskExecutionSystem.lua` - Main system implementation

## Files to Modify
- None (new system)

## Tests
Create test file `testing/__tests__/task_execution_system.lua`:
- Test system initialization and processor registration
- Test task assignment and lifecycle management
- Test processing order (movement before actions)
- Test completion cleanup
- Test performance statistics collection

## Acceptance Criteria
- [ ] TaskExecutionSystem coordinates all task processing
- [ ] Processing order ensures movement happens before actions
- [ ] Task assignment integrates with component pools
- [ ] Completed tasks are properly cleaned up
- [ ] Performance statistics are collected accurately
- [ ] All tests pass
- [ ] Code follows project style guidelines

## Dependencies
- TaskDependencyResolver (from subtask 06)
- MovementSystem (from subtask 07) 
- Task processors (from subtask 08)
- All task components (subtasks 01-03)
- TaskComponentPool (subtask 04)

## Estimated Time
55 minutes

## Notes
This is the central nervous system of the new architecture. It must be robust and performant since it runs every frame. Focus on clear separation of concerns and measurable performance.