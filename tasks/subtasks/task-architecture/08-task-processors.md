# 08 - Task Processors

## Objective
Implement specialized task processors (MiningProcessor, ConstructionProcessor, CleaningProcessor) that handle the actual work logic for each task type using batch processing for optimal performance.

## Scope
- Create MiningProcessor for resource extraction logic
- Create ConstructionProcessor for building progression
- Create CleaningProcessor for maintenance activities
- Implement batch processing patterns for each processor

## Implementation Details

### MiningProcessor
```lua
-- game/systems/MiningProcessor.lua
MiningProcessor = {
  defaultSwingDuration = 1.0,   -- Seconds per mining swing
  defaultSwingsPerResource = 5  -- Swings needed per resource unit
}

function MiningProcessor:processBatch(entities, dt)
  for _, entity in ipairs(entities) do
    local miningTask = EntityManager:getComponent(entity, ComponentType.MINING_TASK)
    local targetHealth = EntityManager:getComponent(miningTask.target, ComponentType.HEALTH)
    
    -- Update swing timer and process mining
    self:processMiningSwing(entity, miningTask, targetHealth, dt)
  end
end
```

### ConstructionProcessor  
```lua
-- game/systems/ConstructionProcessor.lua
ConstructionProcessor = {
  defaultBuildRate = 0.1        -- Progress per second
}

function ConstructionProcessor:processBatch(entities, dt)
  for _, entity in ipairs(entities) do
    local constructionTask = EntityManager:getComponent(entity, ComponentType.CONSTRUCTION_TASK)
    
    -- Check materials and update build progress
    self:processConstruction(entity, constructionTask, dt)
  end
end
```

### CleaningProcessor
```lua  
-- game/systems/CleaningProcessor.lua
CleaningProcessor = {
  defaultCleaningRate = 2.0     -- Dirtiness units per second
}

function CleaningProcessor:processBatch(entities, dt)
  for _, entity in ipairs(entities) do
    local cleaningTask = EntityManager:getComponent(entity, ComponentType.CLEANING_TASK)
    
    -- Process cleaning in radius
    self:processCleaning(entity, cleaningTask, dt)
  end
end
```

### Common Processing Patterns
Each processor implements:
- `processBatch(entities, dt)` - Main batch processing method
- `checkRequirements(entity, task)` - Validate tools/materials
- `updateProgress(task, dt)` - Update task progression
- `handleCompletion(entity, task)` - Process task completion

### Performance Optimizations
- Batch process entities with same task characteristics
- Cache frequently accessed components
- Early exit for entities lacking requirements
- Minimal memory allocation during processing

## Files to Create
- `game/systems/MiningProcessor.lua` - Mining task processor
- `game/systems/ConstructionProcessor.lua` - Construction task processor
- `game/systems/CleaningProcessor.lua` - Cleaning task processor

## Files to Modify
- None (new processors)

## Tests
Create test files:
- `testing/__tests__/mining_processor.lua` - Test mining logic and resource generation
- `testing/__tests__/construction_processor.lua` - Test build progression and materials
- `testing/__tests__/cleaning_processor.lua` - Test area cleaning and dirt removal

Test coverage includes:
- Batch processing with multiple entities
- Progress tracking and completion detection
- Tool/material requirement validation
- Resource generation and consumption
- Performance with large entity batches

## Acceptance Criteria
- [ ] All processors handle batch processing efficiently
- [ ] Mining correctly damages targets and generates resources
- [ ] Construction tracks progress and consumes materials
- [ ] Cleaning processes areas and removes dirt entities
- [ ] Performance acceptable with 50+ entities per processor
- [ ] All tests pass
- [ ] Code follows project style guidelines

## Dependencies
- Task components (subtasks 02-03)
- EntityManager for component access
- Existing Health component system
- Resource and material management systems

## Estimated Time
60 minutes

## Notes
These processors contain the core game logic for different activities. Focus on correctness and performance. The batch processing pattern is critical for maintaining good frame rates with many active entities.