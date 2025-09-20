# Task System Visual Architecture Guide

## ECS-Optimized Component-Based Architecture

### Component Hierarchy Visual

```
TaskComponent (Base Interface)
├── target: Entity|Vec2
├── priority: number (1-6)
├── isComplete: boolean
├── requiredDistance: number
├── estimatedDuration: number
└── entityId: Entity
├─────────────────────────────────
├─ MovementTask
│  ├── path: Vec2[]
│  ├── currentWaypoint: number
│  ├── targetPosition: Vec2
│  └── movementSpeed: number
│
├─ MiningTask
│  ├── swingTimer: number
│  ├── swingsRemaining: number
│  ├── toolRequired: ToolType
│  └── yieldType: ResourceType
│
├─ ConstructionTask
│  ├── blueprintEntity: Entity
│  ├── materialsRequired: table
│  ├── buildProgress: number
│  └── constructionStage: number
│
└─ CleaningTask
   ├── cleaningRadius: number
   ├── dirtEntities: Entity[]
   └── cleaningTool: ToolType
```

### System Processing Flow

```
Frame Update Cycle:

┌─────────────────────────────────────────────────────────────────┐
│                    TaskExecutionSystem:update(dt)              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ 1. DEPENDENCY RESOLUTION PHASE                              ││
│  │                                                             ││
│  │ For each entity with non-Movement tasks:                    ││
│  │  ┌─────────────────────────────────────────────────────────┐││
│  │  │ TaskDependencyResolver:checkMovementNeeded()            │││
│  │  │                                                         │││
│  │  │ Entity[42] has MiningTask → target: Rock[15]            │││
│  │  │ Current pos: (5,3) → Target pos: (12,8)                 │││
│  │  │ Distance: 8.6 > requiredDistance: 1.0                   │││
│  │  │                                                         │││
│  │  │ → ADD MovementTask to Entity[42]                        │││
│  │  │   path: [(6,3), (7,4), ..., (11,8)]                     │││
│  │  │   targetPosition: (12,8)                                │││
│  │  └─────────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ 2. BATCH PROCESSING PHASE                                   ││
│  │                                                             ││
│  │ MovementSystem:processBatch(movingEntities, dt)             ││
│  │  ┌─────────────────────────────────────────────────────────┐││
│  │  │ movingEntities = [Entity[42], Entity[83], Entity[91]]   │││
│  │  │                                                         │││
│  │  │ For each entity:                                        │││
│  │  │   → Update position along path                          │││
│  │  │   → Check if waypoint reached                           │││
│  │  │   → Remove MovementTask if destination reached          │││
│  │  └─────────────────────────────────────────────────────────┘││
│  │                                                             ││
│  │ MiningProcessor:processBatch(miningEntities, dt)            ││
│  │  ┌─────────────────────────────────────────────────────────┐││
│  │  │ miningEntities = [Entity[42]] (only non-moving)         │││
│  │  │                                                         │││
│  │  │ Entity[42]: MiningTask                                  │││
│  │  │   → swingTimer -= dt                                    │││
│  │  │   → if swingTimer <= 0: damage target, reset timer      │││
│  │  │   → if target destroyed: mark isComplete = true         │││
│  │  └─────────────────────────────────────────────────────────┘││
│  │                                                             ││
│  │ ConstructionProcessor:processBatch(constructionEntities, dt)││
│  │ CleaningProcessor:processBatch(cleaningEntities, dt)        ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ 3. COMPLETION CLEANUP PHASE                                 ││
│  │                                                             ││
│  │ For each completed task:                                    ││
│  │   → Remove task component from entity                       ││
│  │   → Trigger completion events (resource generation, etc.)   ││
│  │   → Check for queued tasks to assign                        ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### Entity Component State Transitions

```
Entity Lifecycle Example: Colonist assigned to mine a rock

State 1: Task Assignment
┌─────────────────────────────────────────┐
│ Entity[42]: Colonist                    │
├─────────────────────────────────────────┤
│ Components:                             │
│ • Position: (5, 3)                      │
│ • Velocity: (0, 0)                      │
│ • TaskQueue: [MiningTask{target:Rock15}]│
│ • Schedule: {MINE: 4, CONSTRUCT: 2}     │
└─────────────────────────────────────────┘
                    ↓
         TaskManager:assignTask()
                    ↓
State 2: Task Active + Movement Inserted
┌─────────────────────────────────────────┐
│ Entity[42]: Colonist                    │
├─────────────────────────────────────────┤
│ Components:                             │
│ • Position: (5, 3)                      │
│ • Velocity: (0, 0)                      │
│ • MovementTask: {                       │
│     targetPosition: (12, 8),            │
│     path: [(6,3), (7,4), ..., (11,8)]   │
│   }                                     │
│ • MiningTask: {                         │
│     target: Rock[15],                   │
│     swingsRemaining: 10                 │
│   }                                     │
└─────────────────────────────────────────┘
                    ↓
         MovementSystem:processBatch()
                    ↓
State 3: Moving to Target
┌─────────────────────────────────────────┐
│ Entity[42]: Colonist                    │
├─────────────────────────────────────────┤
│ Components:                             │
│ • Position: (8, 6) ← Updated            │
│ • Velocity: (0.5, 0.3)                  │
│ • MovementTask: {                       │
│     targetPosition: (12, 8),            │
│     currentWaypoint: 4 ← Progressed     │
│   }                                     │
│ • MiningTask: { ← Waiting               │
│     target: Rock[15],                   │
│     swingsRemaining: 10                 │
│   }                                     │
└─────────────────────────────────────────┘
                    ↓
         MovementSystem: destination reached
                    ↓
State 4: Movement Complete, Mining Active
┌─────────────────────────────────────────┐
│ Entity[42]: Colonist                    │
├─────────────────────────────────────────┤
│ Components:                             │
│ • Position: (12, 8)                     │
│ • Velocity: (0, 0)                      │
│ • MiningTask: { ← Now processing        │
│     target: Rock[15],                   │
│     swingTimer: 0.8,                    │
│     swingsRemaining: 7 ← Progressed     │
│   }                                     │
│ (MovementTask removed)                  │
└─────────────────────────────────────────┘
                    ↓
         MiningProcessor:processBatch()
                    ↓
State 5: Task Complete
┌─────────────────────────────────────────┐
│ Entity[42]: Colonist                    │
├─────────────────────────────────────────┤
│ Components:                             │
│ • Position: (12, 8)                     │
│ • Velocity: (0, 0)                      │
│ • TaskQueue: [] ← Empty, ready for new  │
│ (MiningTask removed)                    │
│ (Rock[15] destroyed-resources generated)│
└─────────────────────────────────────────┘
```

### Data Flow Architecture

```
High-Level Data Flow:

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   TaskManager   │    │   EntityManager │    │ ComponentPools  │
│                 │    │                 │    │                 │
│ • openTasks     │───▶│ • entities      │◄──▶│ • miningPool    │
│ • priorities    │    │ • components    │    │ • movementPool  │
│ • assignments   │    │                 │    │ • constructPool │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       ▲                       ▲
         │                       │                       │
         ▼                       │                       │
┌─────────────────┐              │                       │
│   Schedule      │              │                       │
│                 │              │                       │
│ • taskWeights   │              │                       │
│ • priorities    │              │                       │
│ • availability  │              │                       │
└─────────────────┘              │                       │
         │                       │                       │
         │                       │                       │
         ▼                       │                       │
┌─────────────────┐              │                       │
│TaskExecSystem   │──────────────┘                       │
│                 │                                      │
│ Systems:        │◄─────────────────────────────────────┘
│ • MovementSys   │
│ • MiningProc    │
│ • ConstructProc │
│ • CleaningProc  │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│ TaskDependency  │
│   Resolver      │
│                 │
│ • pathfinding   │
│ • distance calc │
│ • movemnt insert│
└─────────────────┘
```

### Memory Layout Optimization

```
Component Storage (Array of Structures vs Structure of Arrays):

Traditional ECS (Structure of Arrays):
┌─────────────────────────────────────────────────────────────────┐
│ MiningTask Components (Contiguous Memory)                       │
├─────────────────────────────────────────────────────────────────┤
│ Entity[42]: {target:Rock15, swings:10, timer:1.0, tool:PICKAXE} │
│ Entity[83]: {target:Rock23, swings:5,  timer:0.3, tool:PICKAXE} │
│ Entity[91]: {target:Rock31, swings:8,  timer:1.5, tool:PICKAXE} │
│ Entity[105]:{target:Rock44, swings:12, timer:0.8, tool:PICKAXE} │
└─────────────────────────────────────────────────────────────────┘

Batch Processing Benefits:
• CPU cache friendly - all MiningTask data together
• SIMD potential - parallel processing of similar operations
• Memory prefetching - predictable access patterns

MovementTask Components:
┌─────────────────────────────────────────────────────────────────┐
│ Entity[42]: {pos:(12,8), target:(12,8), path:[], waypoint:0}    │
│ Entity[67]: {pos:(3,4),  target:(8,9),  path:[...], waypoint:2} │
│ Entity[129]:{pos:(15,2), target:(20,5), path:[...], waypoint:5} │
└─────────────────────────────────────────────────────────────────┘
```
