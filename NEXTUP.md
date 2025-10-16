# NEXTUP – Detailed Implementation Plan

Below is an expanded, step‑by‑step roadmap that turns the current single‑entity task queue architecture into a **full ECS‑optimised component system** as outlined in the design documents.  

---

## 1. Define the *TaskComponent* Base

### Purpose
- Treat every task (movement, mining, construction, etc.) as a **data component** that can be attached to any entity.
- Components are simple tables; the system will manage them via `EntityManager`.

```lua
-- game/components/task/base.lua
local Task = {}
Task.__index = Task

---@class TaskComponent
---@field performerEntity integer            -- owner entity id
---@field target integer|Vec2                -- entity id or world position
---@field priority Priority                 -- 0..6 from enums
---@field isComplete boolean                -- true when finished
---@field requiredDistance number?           -- distance threshold to consider complete
---@field estimatedDuration number?         -- optional expected time
---@field entityId integer                   -- duplicate of performerEntity for convenience

function Task.new(performer, target, priority)
  local self = setmetatable({}, Task)
  self.performerEntity = performer
  self.target = target
  self.priority = priority or enums.Priority.normal
  self.isComplete = false
  return self
end

return Task
```

**Key points**

- `performerEntity` is the entity that owns the task component.
- The component type is *data only* – no methods except `new`.  
  Systems will operate on these tables via iteration.

---

## 2. Implement Concrete Task Sub‑Components

Each specific task extends the base and adds its own fields.

```lua
-- game/components/task/movement.lua
local Task = require("components.task.base")
local enum = require("utils.enums")
local Vec2 = require("utils.Vec2")

---@class MovementTask: Task
---@field path table<integer, Vec2>           -- pre‑computed path
---@field currentPathIndex integer          -- index of the next waypoint
---@field targetPosition Vec2                -- final destination
---@field movementSpeed number              -- speed modifier

local MovementTask = setmetatable({}, { __index = Task })
MovementTask.__index = MovementTask

function MovementTask.new(performer, target, priority)
  local self = Task.new(performer, target, priority)
  -- cast to MovementTask
  self.startPosition = EntityManager:getComponent(performer, enum.ComponentType.POSITION)
  if type(target) == "number" then
    self.targetPosition = EntityManager:getComponent(target, enum.ComponentType.POSITION)
  else
    self.targetPosition = target
  end

  local path = Pathfinder:findPath(
    Vec2.new(math.floor(self.startPosition.x), math.floor(self.startPosition.y)),
    self.targetPosition
  )
  if not path then
    Logger:error("MovementTask: failed to generate path")
    return nil -- abort creation
  end
  self.path = path
  self.currentPathIndex = 0
  return setmetatable(self, MovementTask)
end

function MovementTask:perform(dt)
  local moveto = EntityManager:getComponent(self.performerEntity, enum.ComponentType.MOVETO)
  if moveto then return end -- movement already in progress

  if self.currentPathIndex > #self.path then
    self.isComplete = true
    return
  end

  self.currentPathIndex += 1
  local nextPoint = self.path[self.currentPathIndex]
  EntityManager:addComponent(self.performerEntity, enum.ComponentType.MOVETO, nextPoint)
end

return MovementTask
```

Repeat similar patterns for `MiningTask`, `ConstructionTask`, `CleaningTask`.  
Each will add fields like:

- `swingTimer`, `swingsRemaining` (for mining).
- `materialsRequired`, `buildProgress` (for construction).

---

## 3. Build the **MovementSystem**

### Design
- Batch‑process all entities with a `MovementTask`.
- Use `EntityManager:getEntitiesWithComponent(enum.ComponentType.MOVEMENT_TASK)`.

```lua
-- game/systems/MovementSystem.lua
local enum = require("utils.enums")
local EntityManager = require("systems.EntityManager")

---@class MovementSystem
local MovementSystem = {}

function MovementSystem:update(dt)
  local movingEntities = EntityManager:getEntitiesWithComponent(enum.ComponentType.MOVEMENT_TASK)
  for _, entityId in ipairs(movingEntities) do
    local task = EntityManager:getComponent(entityId, enum.ComponentType.MOVEMENT_TASK)
    task:perform(dt)

    if task.isComplete then
      -- Remove the component when finished
      EntityManager:removeComponent(entityId, enum.ComponentType.MOVEMENT_TASK)
      -- Optionally emit event
      EventBus.publish("MOVEMENT_COMPLETE", { entity = entityId })
    end
  end
end

return MovementSystem
```

**Notes**

- No per‑entity logic; the loop is O(n) over all movement tasks.
- The system can be hooked into `main.lua`’s update cycle.

---

## 4. Create **TaskExecutionSystem**

### Purpose
- Process non‑moving tasks (e.g., mining, construction).
- Delegate to processors that operate on batches.

```lua
-- game/systems/TaskExecutionSystem.lua
local enum = require("utils.enums")
local EntityManager = require("systems.EntityManager")

---@class TaskExecutionSystem
local TaskExecutionSystem = {}

function TaskExecutionSystem:update(dt)
  -- Process all tasks except those with movement
  for _, taskType in ipairs(enum.TaskType) do
    local component = enum.ComponentType[taskType] or nil -- mapping may need to be defined
    if not component then continue end

    local entities = EntityManager:getEntitiesWithComponent(component)
    -- Exclude those that also have MOVEMENT_TASK
    for _, id in ipairs(entities) do
      if EntityManager:hasComponent(id, enum.ComponentType.MOVEMENT_TASK) then
        table.remove(entities, _)
      end
    end

    local processor = TaskProcessorRegistry[taskType]
    if processor then
      processor.processBatch(entities, dt)
    end
  end
end

return TaskExecutionSystem
```

- **`TaskProcessorRegistry`** will map each `TaskType` to its processor (e.g., `MiningProcessor`).  
- Each processor implements a `processBatch()` method.

---

## 5. Build **TaskDependencyResolver**

### Role
- Before executing a task, determine if the entity needs to move.
- If not in range, insert a `MovementTask` into the queue.

```lua
-- game/systems/TaskDependencyResolver.lua
local enum = require("utils.enums")
local EntityManager = require("systems.EntityManager")

---@class TaskDependencyResolver
local TaskDependencyResolver = {}

function TaskDependencyResolver:isInRange(entityId, task)
  local position = EntityManager:getComponent(entityId, enum.ComponentType.POSITION)
  if not task.target then return true end

  local targetPos = nil
  if type(task.target) == "number" then
    targetPos = EntityManager:getComponent(task.target, enum.ComponentType.POSITION)
  else
    targetPos = task.target
  end

  local distance = Vec2.distance(position, targetPos)
  return distance <= (task.requiredDistance or 1.0)
end

function TaskDependencyResolver:insertMovementTask(entityId, target, requiredDistance)
  local movement = MovementTask.new(entityId, target, enums.Priority.normal)
  EntityManager:addComponent(entityId, enum.ComponentType.MOVEMENT_TASK, movement)
end

return TaskDependencyResolver
```

---

## 6. Correctly Initialize `openTasks` in **TaskManager**

```lua
-- systems/TaskManager.lua
local enum = require("utils.enums")
local Task = require("components.task.base")

---@class TaskManager
local TaskManager = {}

function TaskManager.new()
  local self = setmetatable({}, TaskManager)
  self.openTasks = {}
  for _, taskType in ipairs(enum.TaskType) do
    self.openTasks[taskType] = {}
  end
  return self
end

-- Add/remove methods remain the same
```

---

## 7. Implement **Schedule Selection Logic**

`EntitySchedule` is a component that holds priorities and available tasks.

```lua
-- game/components/Schedule.lua (simplified)
local enum = require("utils.enums")

---@class Schedule
---@field priorityTable table<Priority, table<Task>>
function Schedule.new()
  return {
    priorityTable = {}
  }
end

function Schedule:selectNextTask(openTasks)
  -- Iterate from highest to lowest priority
  for p = enum.Priority.emergency, enum.Priority.never, -1 do
    local tasksAtP = openTasks[p]
    if tasksAtP and #tasksAtP > 0 then
      return table.remove(tasksAtP, 1) -- pick first available task
    end
  end
  return nil
end
```

The `TaskManager.update()` will now call this method.

---

## 8. Add “Wander” Fallback

If no tasks are available:

```lua
-- game/components/Idle.lua (simple random wander)
local enum = require("utils.enums")
local Vec2 = require("utils.Vec2")

function Idle.wander(entityId)
  local pos = EntityManager:getComponent(entityId, enum.ComponentType.POSITION)
  -- Pick a random target within a radius
  local randDir = Vec2.new(math.random(-1,1), math.random(-1,1))
  local targetPos = Vec2.add(pos, randDir * 10) -- arbitrary wander distance

  local movement = MovementTask.new(entityId, targetPos, enums.Priority.low)
  EntityManager:addComponent(entityId, enum.ComponentType.MOVEMENT_TASK, movement)
end
```

---

## 9. Create Component Pools

```lua
-- game/utils/ComponentPool.lua
local pool = {}

---@class ComponentPool
function ComponentPool:new()
  local self = setmetatable({}, { __index = self })
  self.pool = {}
  return self
end

function ComponentPool:acquire()
  if #self.pool > 0 then
    return table.remove(self.pool, 1)
  else
    return nil -- caller must create new instance
  end
end

function ComponentPool:release(obj)
  table.insert(self.pool, obj)
end

return ComponentPool
```

For each task type, instantiate a pool (`MovementTaskPool`, `MiningTaskPool`) and reuse objects.

---

## 10. Integrate EventBus

```lua
-- systems/EventBus.lua (simplified)
local EventBus = {}

function EventBus.subscribe(eventName, callback)
  if not EventBus.listeners[eventName] then
    EventBus.listeners[eventName] = {}
  end
  table.insert(EventBus.listeners[eventName], callback)
end

function EventBus.publish(eventName, data)
  local listeners = EventBus.listeners[eventName]
  if listeners then
    for _, cb in ipairs(listeners) do
      cb(data)
    end
  end
end

return EventBus
```

- Systems can subscribe to `MOVEMENT_COMPLETE`, `ACTION_COMPLETE`.
- Example: `TaskExecutionSystem` subscribes to `MOVEMENT_COMPLETE` to start the next task.

---

## 11. Batch Pathfinding / Spatial Indexing (Optional)

If performance is critical, implement a simple grid index:

```lua
-- game/systems/SpatialIndex.lua
local Grid = {}
function Grid:new(cellSize)
  local self = setmetatable({}, { __index = self })
  self.cellSize = cellSize
  self.cells = {} -- map of "x:y" -> list of entity ids
  return self
end

function Grid:register(entityId, position)
  local key = string.format("%d:%d", math.floor(position.x / self.cellSize), math.floor(position.y / self.cellSize))
  if not self.cells[key] then self.cells[key] = {} end
  table.insert(self.cells[key], entityId)
end

function Grid:query(position, radius)
  -- return entities within radius (simple loop over adjacent cells)
end
```

Use this grid in `PathFinder` to accelerate path queries.

---

## 12. Remove / Dispose Tasks After Completion

- Each system should remove the task component once `isComplete == true`.
- Optionally push a new task from the queue or trigger idle behavior.
- Ensure no lingering components remain that could cause memory leaks.

```lua
-- Example in MovementSystem:
if task.isComplete then
  EntityManager:removeComponent(entityId, enum.ComponentType.MOVEMENT_TASK)
end
```

---

## Summary of Next Steps

1. **Refactor existing `TaskQueue` and `TaskManager`.**  
   Replace the queue with component‑based tasks.
2. **Implement the new components (MovementTask, MiningTask, etc.).**
3. **Create the batch systems (`MovementSystem`, `TaskExecutionSystem`).**
4. **Add dependency resolver and schedule logic.**
5. **Introduce component pools for reuse.**
6. **Hook EventBus into systems.**
7. **Run unit tests** (existing tests will need adjustments to match new architecture).
8. **Lint & build** – ensure no syntax errors or style violations.
