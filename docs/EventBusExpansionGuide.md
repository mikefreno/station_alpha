# EventBus Expansion Guide

This document outlines how to expand EventBus usage throughout the game systems for better decoupling and maintainability.

## Event Types to Implement

### Core Game Events
- `game_paused` - When game state changes to paused/unpaused
- `map_loaded` - When map data has been loaded and initialized
- `resource_changed` - When resources are added/removed
- `entity_selected` - When an entity is selected by UI
- `entity_deselected` - When an entity is deselected by UI

### Input Events
- `input_keypressed` - When keyboard input is processed
- `input_mousepressed` - When mouse input is processed
- `input_wheeled` - When mouse wheel is moved

### Task Management Events
- `task_completed` - When a task is completed
- `task_assigned` - When a new task is assigned to an entity
- `task_failed` - When a task fails

### Entity Lifecycle Events
- `entity_created` - When a new entity is created
- `entity_destroyed` - When an entity is destroyed

## Implementation Strategy

1. **Add Event Emission**: Components should emit events when significant state changes occur
2. **Add Event Listeners**: Other components should register listeners for relevant events
3. **Create Event Handlers**: Implement proper event handling logic in the listening components
4. **Test Integration**: Verify that events properly propagate through the system

## Example Implementation Patterns

### Input System Events
```lua
-- In Input.lua
function InputSystem:keypressed(key, scancode, isrepeat)
  EventBus:emit("input_keypressed", { 
    key = key, 
    scancode = scancode, 
    isrepeat = isrepeat 
  })
end

-- In other components that listen to input
EventBus:on("input_keypressed", function(data)
  if data.key == "space" then
    -- Handle spacebar press
  end
end)
```

### Task Management Events
```lua
-- In TaskManager.lua
function TaskManager:completeTask(task, entity)
  EventBus:emit("task_completed", { 
    task = task, 
    entity = entity 
  })
end

-- In components that listen to task completion
EventBus:on("task_completed", function(data)
  -- Update UI, resource tracking, etc.
end)
```

### Entity Lifecycle Events
```lua
-- In EntityManager.lua or similar
function EntityManager:createEntity(...)
  local entity = baseCreateEntity(...)
  EventBus:emit("entity_created", { entity = entity })
  return entity
end

-- In components that listen to entity creation
EventBus:on("entity_created", function(data)
  -- Initialize component-specific logic
end)
```

## Testing Strategy

1. **Mock EventBus** in tests to capture event emissions
2. **Verify listeners** are properly registered
3. **Test event handling** with various data scenarios
4. **Ensure proper cleanup** of listeners when components are destroyed