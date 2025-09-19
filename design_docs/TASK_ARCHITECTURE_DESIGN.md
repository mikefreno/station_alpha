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

---

## Approach 2: Hierarchical State Machine with Action Separators

### Overview
This approach treats each colonist as a hierarchical state machine where high-level states (Moving, Working, Idle) contain task-specific sub-states. Movement becomes a first-class concern separate from task execution.

### Architecture Components

#### Core Components
```lua
-- New: ActionState - Base class for all colonist states
ActionState = {
  -- enter(entity, context) - Called when state begins
  -- update(entity, dt) - Called each frame
  -- exit(entity) - Called when state ends
  -- canTransition(entity, newState) - Validation logic
}

-- Enhanced: Task becomes purely data-driven
Task = {
  type = TaskType,
  target = Entity|Vec2,
  requirements = {}, -- What the colonist needs to complete this
  estimatedDuration = number,
  priority = number,
  context = {} -- Task-specific data
}

-- New: ActionExecutor - Handles task-specific logic
ActionExecutor = {
  -- execute(entity, task, dt) -> ActionResult
  -- canExecute(entity, task) -> boolean
  -- getRequiredDistance(task) -> number
}
```

#### State Hierarchy
```
ColonistStateMachine
├── IdleState
├── MovingState
│   ├── PathfindingSubState
│   ├── WalkingSubState
│   └── NavigatingObstacleSubState
└── WorkingState
    ├── MiningSubState
    ├── ConstructingSubState
    ├── CleaningSubState
    └── ... (other task-specific states)
```

#### Flow Control
1. **Task Assignment**: TaskManager assigns tasks to colonist queues
2. **State Transition**: Colonist evaluates current state and transitions as needed
3. **Movement Orchestration**: MovingState handles all pathfinding and navigation
4. **Action Execution**: WorkingState delegates to specific ActionExecutors
5. **Completion**: States signal completion back to the state machine

### Advantages
- ✅ Complete separation of movement from task logic
- ✅ Easy to add new task types without touching core systems
- ✅ Clear state transitions and debugging capabilities
- ✅ Supports complex behaviors (interruptions, multi-stage tasks)
- ✅ Scalable architecture for complex AI behaviors

### Disadvantages
- ❌ Higher initial complexity
- ❌ More files and classes to maintain
- ❌ Potential performance overhead from state machine

### Implementation Effort: **High** (2-3 weeks)

---

## Approach 3: Command Pattern with Movement Decorators

### Overview
Each task becomes a Command object that can be decorated with movement requirements. Movement becomes a decorator that wraps action commands.

### Architecture Components

#### Core Components
```lua
-- New: Command interface
Command = {
  -- execute(entity, dt) -> CommandResult
  -- canExecute(entity) -> boolean
  -- isComplete(entity) -> boolean
  -- getEstimatedDuration() -> number
}

-- New: MovementDecorator - Wraps commands with movement
MovementDecorator = {
  wrappedCommand = Command,
  targetPosition = Vec2,
  requiredDistance = number,
  -- execute() first moves to position, then executes wrapped command
}

-- Enhanced: TaskExecutors implement Command interface
MiningCommand = Command:extend()
ConstructionCommand = Command:extend()
CleaningCommand = Command:extend()
```

#### Command Composition
```lua
-- Example task creation
local miningTask = MovementDecorator.new(
  MiningCommand.new(targetRock),
  targetPosition,
  1.0 -- required distance
)

-- Commands can be chained
local complexTask = SequentialCommand.new({
  MovementDecorator.new(MiningCommand.new(rock1), pos1, 1.0),
  MovementDecorator.new(MiningCommand.new(rock2), pos2, 1.0),
  MovementDecorator.new(DropOffCommand.new(stockpile), pos3, 1.0)
})
```

#### Flow Control
1. **Task Creation**: Tasks are composed of decorated commands
2. **Execution**: Commands handle their own prerequisites (including movement)
3. **Chaining**: Complex tasks become command sequences
4. **Interruption**: Commands can be cancelled and replaced

### Advantages
- ✅ Flexible composition of behaviors
- ✅ Movement is cleanly separated but automatically handled
- ✅ Easy to create complex multi-step tasks
- ✅ Reusable command components
- ✅ Clear separation of concerns

### Disadvantages
- ❌ Can become complex with deeply nested decorators
- ❌ Debugging command chains can be difficult
- ❌ Memory overhead from command objects

### Implementation Effort: **Medium** (1-2 weeks)

---

## Approach 4: Reactive Task Decomposer

### Overview
Tasks are automatically decomposed into atomic actions by a central decomposer. Movement becomes one type of atomic action that's automatically inserted when needed.

### Architecture Components

#### Core Components
```lua
-- Enhanced: Task becomes high-level intent
Task = {
  intent = TaskIntent, -- MINE_ROCK, BUILD_WALL, etc.
  target = Entity|Vec2,
  parameters = {},
  decomposed = false
}

-- New: TaskDecomposer - Breaks tasks into atomic actions
TaskDecomposer = {
  -- decompose(task) -> AtomicAction[]
  -- getMovementRequirement(task) -> MovementAction|nil
}

-- New: AtomicAction - Smallest unit of work
AtomicAction = {
  type = ActionType, -- MOVE, MINE_SWING, BUILD_PLACE, etc.
  target = Entity|Vec2,
  duration = number,
  requirements = {} -- Prerequisites to execute
}

-- Enhanced: TaskQueue works with atomic actions
TaskQueue = {
  currentAction = AtomicAction,
  actionQueue = AtomicAction[],
  -- Processes atomic actions sequentially
}
```

#### Decomposition Examples
```lua
-- High-level task: "Mine this rock"
local miningTask = Task.new(TaskIntent.MINE_ROCK, rockEntity)

-- Decomposer automatically creates:
{
  AtomicAction.new(ActionType.MOVE, rockPosition, 2.0),
  AtomicAction.new(ActionType.EQUIP_TOOL, pickaxe, 0.5),
  AtomicAction.new(ActionType.MINE_SWING, rockEntity, 1.0),
  AtomicAction.new(ActionType.MINE_SWING, rockEntity, 1.0),
  -- ... continues until rock is depleted
}
```

#### Flow Control
1. **Task Assignment**: High-level tasks assigned to colonists
2. **Decomposition**: TaskDecomposer breaks tasks into atomic actions
3. **Execution**: TaskQueue processes atomic actions sequentially
4. **Adaptation**: Failed actions trigger re-decomposition

### Advantages
- ✅ Very simple task creation (just intent + target)
- ✅ Automatic movement insertion
- ✅ Easy to optimize and cache decompositions
- ✅ Consistent behavior across all task types
- ✅ Great for data-driven task definitions

### Disadvantages
- ❌ Less control over specific behaviors
- ❌ Decomposer can become complex central bottleneck
- ❌ Difficult to handle dynamic/reactive tasks
- ❌ May feel "automated" rather than intentional

### Implementation Effort: **Medium** (1.5-2 weeks)

---

## Approach 5: Event-Driven Cooperative Multitasking (LOWEST RANK)

### Overview
Tasks become coroutines that cooperatively yield control. Movement and actions are handled through an event system where tasks subscribe to completion events.

### Architecture Components

#### Core Components
```lua
-- New: TaskCoroutine - Each task runs as a coroutine
TaskCoroutine = {
  routine = coroutine,
  entity = Entity,
  status = CoroutineStatus,
  -- yield_move(target) - Yields until movement complete
  -- yield_action(action, duration) - Yields for action duration
}

-- New: EventBus - Coordinates between tasks and systems
EventBus = {
  -- subscribe(event, callback)
  -- publish(event, data)
  -- Events: MOVEMENT_COMPLETE, ACTION_COMPLETE, etc.
}

-- Enhanced: Task becomes a coroutine function
function miningTaskRoutine(entity, target)
  -- Move to target
  yield_move(target)
  
  -- Equip tool
  yield_action("equip_pickaxe", 0.5)
  
  -- Mine until depleted
  while target:hasHealth() do
    yield_action("mine_swing", 1.0)
  end
end
```

#### Flow Control
1. **Task Start**: Task coroutine is created and resumed
2. **Yielding**: Task yields control when waiting for movement/actions
3. **Event Coordination**: EventBus notifies tasks when operations complete
4. **Resumption**: Tasks resume after their waited-for events occur

### Advantages
- ✅ Very natural task scripting (reads like pseudocode)
- ✅ Easy to create complex, multi-step behaviors
- ✅ Built-in support for waiting and coordination
- ✅ Flexible interruption and resumption

### Disadvantages
- ❌ Coroutines can be difficult to debug
- ❌ Memory management complexity with many coroutines
- ❌ Event coordination can become tangled
- ❌ Performance concerns with frequent yield/resume
- ❌ Error handling in coroutines is complex

### Implementation Effort: **High** (2-3 weeks)

---

## Recommendation Summary

### Ranking Rationale (Updated for ECS + Performance):

1. **ECS-Optimized Component-Based** - Maximum performance with hundreds of entities, true ECS alignment
2. **Hierarchical State Machine** - Good balance of control and maintainability, but less ECS-optimal
3. **Command Pattern** - Good separation of concerns but object overhead
4. **Reactive Decomposer** - Simple to use but centralized bottleneck
5. **Event-Driven Coroutines** - Powerful but performance and complexity concerns

### Suggested Implementation Order:

For your ECS game with performance requirements, I recommend **Approach 1 (ECS-Optimized Component-Based)** because:
- **Performance**: Batch processing scales to hundreds of entities efficiently
- **ECS Alignment**: True components and systems architecture
- **Memory Efficiency**: Component pooling and spatial indexing optimizations
- **Flexibility**: Easy to add new task types without touching core systems
- **Debugging**: Clear component state and system boundaries
- **Scalability**: Designed for high entity counts from the ground up

### Migration Strategy:

1. Create base TaskComponent interface and MovementTask component
2. Implement TaskExecutionSystem and MovementSystem for batch processing
3. Convert existing task types to components (MiningTask, etc.)
4. Create task-specific processors (MiningProcessor, etc.)
5. Add TaskDependencyResolver for automatic movement insertion
6. Optimize with component pooling and spatial indexing

This approach maximizes performance while maintaining the flexibility you need for your colonist AI system.
