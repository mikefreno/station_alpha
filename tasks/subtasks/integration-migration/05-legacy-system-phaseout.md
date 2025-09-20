# Subtask 05: Legacy System Phaseout

## Overview
Systematically replace direct usage of legacy Task.lua perform() methods with ECS TaskComponent equivalents, while maintaining backward compatibility during the transition period.

## Current Legacy Usage Analysis
Based on codebase analysis, the following areas use legacy Task.lua directly:
- `game/components/Task.lua:33` - perform() method with hardcoded logic
- Various system files importing Task for manual task execution
- Entity creation code instantiating Task objects directly

## Phaseout Strategy

### 1. Legacy Task Usage Identification
- Scan all files for direct Task.lua imports and usage
- Identify manual task.perform() calls in systems
- Map legacy task creation patterns to ECS equivalents

### 2. Gradual Replacement Process
```lua
-- Phase 1: Parallel operation (both systems working)
-- Phase 2: Gradual migration (file by file replacement)
-- Phase 3: Legacy deprecation (warnings for legacy usage)
-- Phase 4: Legacy removal (clean legacy code)
```

### 3. Migration Patterns

#### Legacy Task Creation
```lua
-- Before (Legacy)
local task = Task.new("mining", targetPos, entityId)
TaskQueue:addTask(entityId, task)

-- After (ECS)
local component = TaskAdapter:createFromLegacy(task)
TaskComponentPool:addComponent(entityId, ComponentType.MINING, component)
```

#### Legacy Task Execution
```lua
-- Before (Legacy)
task:perform(dt)

-- After (ECS)
-- Handled automatically by TaskExecutionSystem
```

## Implementation Steps

### Files to Modify
1. **Replace Legacy Imports**: Update require statements across codebase
2. **Update Task Creation**: Convert Task.new() calls to ECS component creation
3. **Remove Direct Execution**: Eliminate manual task.perform() calls
4. **Update Tests**: Migrate test files to use ECS patterns

### Specific Areas
- `game/systems/TaskManager.lua` - Remove legacy task iteration
- `game/components/TaskQueue.lua` - Deprecate legacy task storage
- Entity creation systems - Use TaskComponentPool instead of Task.new()
- Movement/action systems - Trust TaskExecutionSystem for processing

## Compatibility Considerations

### Backward Compatibility
- TaskAdapter maintains legacy Task interface for external code
- Legacy task objects continue to work through adapter layer
- No breaking changes to existing save files or external integrations

### Performance Impact
- ECS systems provide better performance for high entity counts
- Legacy adapter adds minimal overhead during transition
- Component pooling reduces garbage collection pressure

## Testing Requirements
- Verify all existing functionality preserved during migration
- Test performance benchmarks show improvement or parity
- Validate save/load compatibility with mixed legacy/ECS data
- Ensure smooth operation during gradual migration phase

## Success Criteria
- [ ] All direct Task.lua usage identified and documented
- [ ] Migration plan for each legacy usage point created
- [ ] Critical systems successfully migrated to ECS
- [ ] Legacy Task.lua usage reduced by 80%+ 
- [ ] Performance improvements measurable in high-load scenarios
- [ ] Zero regression in existing functionality

## Risk Mitigation
- **Rollback Plan**: Quick revert to legacy mode if issues arise
- **Incremental Migration**: One system at a time to isolate problems
- **Extensive Testing**: Comprehensive test coverage before each phase
- **User Communication**: Clear deprecation warnings for external users

## Dependencies
- Requires: Subtasks 01-04 (full ECS integration complete)
- Enables: Subtasks 06-08 (testing, optimization, cleanup)

## Estimated Effort
**High** - Significant codebase changes requiring careful coordination