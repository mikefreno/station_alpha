# Game Systems Overview

This directory contains core game systems that manage different aspects of the game state and behavior.

## Systems List

- **EventBus** - Event broadcasting system for loose coupling between components
- **EntityManager** - Manages game entities and their components
- **Input** - Handles user input events
- **MapManager** - Manages map data and generation
- **PathFinder** - Finds paths for entities to navigate
- **Position** - Manages entity positions in the world
- **Render** - Handles rendering of game elements
- **TaskManager** - Manages task assignments and execution

## EventBus Integration

All systems should use the EventBus system for communication. This promotes loose coupling and makes components more testable and maintainable.

### Common Events Used:
- `entity_selected` - When an entity is selected by UI
- `entity_deselected` - When an entity is deselected by UI  
- `game_paused` - When game state changes to paused
- `resource_changed` - When resources are added/removed
- `task_completed` - When a task is completed
- `input_keypressed` - When keyboard input is processed
- `input_mousepressed` - When mouse input is processed

## Architecture Guidelines

1. **Components** should register listeners for relevant events and emit events when they change state
2. **Systems** should emit events when significant game state changes occur
3. **UI Components** should emit events when user interactions happen
4. **All communication** between components should go through the EventBus system