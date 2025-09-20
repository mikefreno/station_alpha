# 01 - Base Task Component Interface

## Objective
Create the foundational TaskComponent interface that all task types inherit from, establishing the core data structure and shared functionality for the new ECS-optimized task system.

## Scope
- Define the base TaskComponent class with common properties
- Implement core methods for task lifecycle management
- Add component type enumeration for task components
- Create type annotations for Lua language server

## Implementation Details

### TaskComponent Base Interface
```lua
-- game/components/TaskComponent.lua
TaskComponent = {
  target = Entity|Vec2,           -- What/where to act upon
  priority = number,              -- Task priority (1-6)
  isComplete = boolean,           -- Completion status
  requiredDistance = number,      -- How close to target needed
  estimatedDuration = number,     -- Expected completion time
  entityId = Entity               -- Owner entity
}
```

### Core Methods
- `TaskComponent.new(target, priority, requiredDistance)` - Constructor
- `TaskComponent:isValid()` - Validates task state
- `TaskComponent:markComplete()` - Sets completion flag
- `TaskComponent:getProgress()` - Returns completion percentage (0.0-1.0)

### Component Type Updates
Add new component types to `game/utils/enums.lua`:
- `TASK_COMPONENT_BASE = 100`
- `MOVEMENT_TASK = 101` 
- `MINING_TASK = 102`
- `CONSTRUCTION_TASK = 103`
- `CLEANING_TASK = 104`

## Files to Create
- `game/components/TaskComponent.lua` - Base interface implementation

## Files to Modify
- `game/utils/enums.lua` - Add new ComponentType entries

## Tests
Create test file `testing/__tests__/task_component.lua`:
- Test component creation with valid parameters
- Test validation methods
- Test completion state management
- Test invalid parameter handling

## Acceptance Criteria
- [ ] TaskComponent base class created with all required properties
- [ ] Constructor validates input parameters appropriately
- [ ] Component type enums updated in enums.lua
- [ ] All tests pass
- [ ] Code follows project style guidelines (stylua, lua-language-server)

## Dependencies
- EntityManager for component registration
- Logger for error handling
- Existing Vec2 utility class

## Estimated Time
45 minutes

## Notes
This is the foundation for all other task components. Ensure the interface is flexible enough to accommodate different task types while maintaining performance for batch processing.