# Task and Movement Architecture Design Document

## Current System Analysis

Your current system has the following components:
- **Task**: Basic task definition with type and target
- **TaskQueue**: Sequential task execution for entities
- **TaskManager**: Global task assignment and pathfinding coordination
- **PositionSystem**: Movement handling via MoveTo components
- **Schedule**: Priority-based task selection

### Current Issues Identified:
1. Movement is tightly coupled to specific task logic
2. Task-specific implementations leak into core systems
3. No clear separation between movement, action execution, and task orchestration
4. Pathfinding creates direct MoveTo tasks, bypassing task abstraction

---

## Approach 1: ECS-Optimized Component-Based Task Architecture (RECOMMENDED)

### Overview
This approach treats tasks as data components that systems process in batches for maximum performance. Movement becomes a primitive component that other task components depend on. Perfect for ECS architectures with hundreds of entities.

### Architecture Components

#### Core Task Interface
```lua
-- Base interface that all task components implement
TaskComponent = {
  target = Entity|Vec2,           -- What/where to act upon
  priority = number,              -- Task priority (1-6)
  isComplete = boolean,           -- Completion status
  requiredDistance = number,      -- How close to target needed
  estimatedDuration = number,     -- Expected completion time
  entityId = Entity              -- Owner entity
}
```

#### Task-Specific Components
```lua
-- Movement is a primitive component - all other tasks may depend on it
MovementTask = TaskComponent:extend()
MovementTask = {
  path = Vec2[],                 -- Current path to follow
  currentWaypoint = number,      -- Index in path array
  targetPosition = Vec2,         -- Final destination
  movementSpeed = number         -- Movement rate modifier
}

-- Mining task component
MiningTask = TaskComponent:extend()
MiningTask = {
  swingTimer = number,           -- Time until next swing
  swingsRemaining = number,      -- Swings needed to complete
  toolRequired = ToolType,       -- Required tool type
  yieldType = ResourceType       -- What resource this produces
}

-- Construction task component  
ConstructionTask = TaskComponent:extend()
ConstructionTask = {
  blueprintEntity = Entity,      -- What to build
  materialsRequired = table,     -- Required materials map
  buildProgress = number,        -- 0.0 to 1.0 completion
  constructionStage = number     -- Multi-stage construction
}

-- Cleaning task component
CleaningTask = TaskComponent:extend()
CleaningTask = {
  cleaningRadius = number,       -- Area of effect
  dirtEntities = Entity[],       -- Entities to clean
  cleaningTool = ToolType        -- Required cleaning implement
}
```

#### High-Performance Systems
```lua
-- Batch processes all movement - highest priority system
MovementSystem = {
  -- update(dt) - processes all entities with MovementTask
  -- Uses spatial partitioning for pathfinding optimization
  -- Removes MovementTask when destination reached
}

-- Coordinates task execution and movement insertion
TaskExecutionSystem = {
  -- update(dt) - manages task lifecycle
  -- Automatically inserts MovementTask when entities need to move
  -- Delegates to specific task processors
}

-- Task-specific processors (pure functions for performance)
MiningProcessor = {
  -- processBatch(entitiesWithMiningTask, dt)
  -- Updates mining progress, handles tool requirements
  -- Triggers resource generation on completion
}

ConstructionProcessor = {
  -- processBatch(entitiesWithConstructionTask, dt) 
  -- Updates build progress, consumes materials
  -- Handles multi-stage construction logic
}

CleaningProcessor = {
  -- processBatch(entitiesWithCleaningTask, dt)
  -- Processes cleaning in radius, removes dirt entities
  -- Updates cleanliness metrics
}
```

#### Dependency Resolution
```lua
-- TaskDependencyResolver - handles movement insertion
TaskDependencyResolver = {
  -- checkMovementNeeded(entity, taskComponent) -> boolean
  -- insertMovementTask(entity, targetPosition, requiredDistance)
  -- removeCompletedDependencies(entity)
}
```

### Flow Control

#### 1. Task Assignment Phase
```lua
-- TaskManager assigns tasks to entities
TaskManager:assignTask(entityId, MiningTask.new(rockEntity))
```

#### 2. Dependency Resolution Phase  
```lua
-- TaskExecutionSystem checks if movement needed
if not TaskDependencyResolver:isInRange(entity, task) then
  TaskDependencyResolver:insertMovementTask(entity, task.target, task.requiredDistance)
end
```

#### 3. Batch Processing Phase
```lua
function TaskExecutionSystem:update(dt)
  -- Process movement first (highest priority)
  local movingEntities = EntityManager:getEntitiesWithComponent(ComponentType.MOVEMENT_TASK)
  MovementSystem:processBatch(movingEntities, dt)
  
  -- Process other tasks only for non-moving entities
  local miningEntities = EntityManager:getEntitiesWithComponent(ComponentType.MINING_TASK)
                                     :exclude(ComponentType.MOVEMENT_TASK)
  MiningProcessor:processBatch(miningEntities, dt)
  
  local constructionEntities = EntityManager:getEntitiesWithComponent(ComponentType.CONSTRUCTION_TASK)
                                           :exclude(ComponentType.MOVEMENT_TASK)  
  ConstructionProcessor:processBatch(constructionEntities, dt)
  
  -- Handle completed tasks and dependency updates
  self:processCompletedTasks()
end
```

#### 4. Completion and Cleanup Phase
```lua
-- Remove completed task components
-- Insert new tasks from queue
-- Update entity schedules
```

### Performance Optimizations

#### Batch Processing Benefits
- **Cache Efficiency**: Process entities with same component types together
- **Reduced Branching**: Type-specific processors avoid runtime type checks  
- **Memory Locality**: Components stored contiguously in memory
- **Vectorizable Operations**: Bulk updates on similar data structures

#### Memory Management
```lua
-- Component pools to avoid allocations
TaskComponentPool = {
  miningTaskPool = {},
  constructionTaskPool = {},
  movementTaskPool = {},
  -- Reuse components instead of creating new ones
}
```

#### Spatial Optimizations
```lua
-- Spatial indexing for movement and proximity checks
SpatialIndex = {
  -- Group entities by grid cells for efficient queries
  -- Optimize pathfinding with cached regions
  -- Batch proximity calculations
}
```

### Component Integration Example

#### Adding a New Task Type
```lua
-- 1. Define the component
RepairTask = TaskComponent:extend()
RepairTask = {
  targetDamage = number,
  repairRate = number,
  toolRequired = ToolType
}

-- 2. Create the processor
RepairProcessor = {
  processBatch = function(entities, dt)
    for _, entity in ipairs(entities) do
      local repairTask = EntityManager:getComponent(entity, ComponentType.REPAIR_TASK)
      local target = EntityManager:getComponent(repairTask.target, ComponentType.HEALTH)
      
      -- Update repair progress
      target.currentHealth = math.min(target.maxHealth, 
                                     target.currentHealth + repairTask.repairRate * dt)
      
      -- Mark complete if fully repaired
      if target.currentHealth >= target.maxHealth then
        repairTask.isComplete = true
      end
    end
  end
}

-- 3. Register with TaskExecutionSystem
TaskExecutionSystem:registerProcessor(ComponentType.REPAIR_TASK, RepairProcessor)
```

### Advantages
- ✅ **Maximum Performance**: Batch processing with minimal overhead
- ✅ **True ECS Alignment**: Components and systems pattern
- ✅ **Scalable**: Handles hundreds of entities efficiently  
- ✅ **Extensible**: New task types require only component + processor
- ✅ **Memory Efficient**: Component pooling and spatial indexing
- ✅ **Debuggable**: Clear component state inspection
- ✅ **Flexible**: Easy task composition and dependencies

### Disadvantages
- ❌ **Initial Complexity**: Requires understanding of batch processing patterns
- ❌ **Less Object-Oriented**: More functional/data-oriented approach
- ❌ **System Coordination**: Need careful ordering of system updates

### Implementation Effort: **Medium** (1-2 weeks)


