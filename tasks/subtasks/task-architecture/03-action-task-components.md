# 03 - Action Task Components

## Objective
Implement specific action task components (MiningTask, ConstructionTask, CleaningTask) that extend the base TaskComponent and define the data structures for different types of work activities.

## Scope
- Create MiningTask component for resource extraction
- Create ConstructionTask component for building activities
- Create CleaningTask component for maintenance work
- Ensure all components follow the same interface patterns

## Implementation Details

### MiningTask Component
```lua
-- game/components/MiningTask.lua
MiningTask = TaskComponent:extend()
MiningTask = {
  swingTimer = number,           -- Time until next swing (countdown)
  swingsRemaining = number,      -- Swings needed to complete
  toolRequired = ToolType,       -- Required tool type (PICKAXE, etc.)
  yieldType = ResourceType,      -- What resource this produces
  swingDuration = number         -- Time per swing (default 1.0 seconds)
}
```

### ConstructionTask Component
```lua
-- game/components/ConstructionTask.lua
ConstructionTask = TaskComponent:extend()
ConstructionTask = {
  blueprintEntity = Entity,      -- What to build (entity reference)
  materialsRequired = table,     -- Required materials map {resourceType: amount}
  buildProgress = number,        -- 0.0 to 1.0 completion percentage
  constructionStage = number,    -- Multi-stage construction (0-based)
  buildRate = number            -- Progress per second
}
```

### CleaningTask Component
```lua
-- game/components/CleaningTask.lua
CleaningTask = TaskComponent:extend()
CleaningTask = {
  cleaningRadius = number,       -- Area of effect (in tiles)
  dirtEntities = Entity[],       -- Entities to clean (list of dirty objects)
  cleaningTool = ToolType,       -- Required cleaning implement
  cleaningRate = number,         -- Cleaning units per second
  totalDirtiness = number        -- Total dirtiness to clean
}
```

### Core Methods for Each
Each component includes:
- `Component.new(target, ...)` - Constructor with specific parameters
- `Component:updateProgress(dt)` - Update internal timers/progress
- `Component:canPerform(entity)` - Check if entity can perform task
- `Component:getProgress()` - Return completion percentage
- `Component:getRemainingWork()` - Return estimated time to completion

## Files to Create
- `game/components/MiningTask.lua` - Mining task implementation
- `game/components/ConstructionTask.lua` - Construction task implementation  
- `game/components/CleaningTask.lua` - Cleaning task implementation

## Files to Modify
- `game/utils/enums.lua` - Add ToolType and ResourceType enums if needed

## Tests
Create test files:
- `testing/__tests__/mining_task.lua` - Test mining task logic
- `testing/__tests__/construction_task.lua` - Test construction task logic
- `testing/__tests__/cleaning_task.lua` - Test cleaning task logic

Test coverage includes:
- Component creation with valid parameters
- Progress tracking and timer updates
- Tool and resource requirement validation
- Completion detection
- Invalid parameter handling

## Acceptance Criteria
- [ ] All three task components extend TaskComponent correctly
- [ ] Each component has appropriate data fields for its task type
- [ ] Progress tracking works correctly for each task type
- [ ] Tool and resource requirements are properly validated
- [ ] All tests pass with good coverage
- [ ] Code follows project style guidelines

## Dependencies
- TaskComponent base class (from subtask 01)
- ToolType and ResourceType enumerations
- Entity type definitions
- Logger for error handling

## Estimated Time
55 minutes

## Notes
These components are pure data structures. The actual processing logic will be implemented in the task processors (subtask 08). Focus on clean data representation and validation methods.