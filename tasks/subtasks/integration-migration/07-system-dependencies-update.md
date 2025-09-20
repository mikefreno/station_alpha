# Subtask 07: System Dependencies Update

## Overview
Update and optimize dependent systems to work seamlessly with the new ECS task architecture, ensuring proper integration and eliminating dependencies on legacy task components.

## Affected Systems Analysis

### Core Game Systems
- `game/systems/EntityManager.lua` - Entity lifecycle and component management
- `game/systems/Input.lua` - User input handling for task creation
- `game/systems/Render.lua` - Visual representation of task states
- `game/systems/MapManager.lua` - Spatial queries and world interaction

### Utility Systems  
- `game/systems/Position.lua` - Spatial positioning for task targeting
- `game/systems/PathFinder.lua` - Path calculation for movement tasks
- `game/systems/Persistence.lua` - Save/load functionality for task data

### UI Components
- `game/components/RightClickMenu.lua` - Task creation interface
- `game/components/PauseMenu.lua` - Game state management
- `game/components/BottomBar.lua` - Task status display

## Integration Points

### 1. EntityManager Integration
**Current Issues:**
- Direct Task object management in entity lifecycle
- Manual task cleanup on entity destruction

**Required Changes:**
```lua
-- Before (Legacy)
function EntityManager:destroyEntity(entityId)
    local taskQueue = entityManager.entities[entityId].taskQueue
    if taskQueue then
        taskQueue:clearAllTasks()
    end
end

-- After (ECS)
function EntityManager:destroyEntity(entityId) 
    TaskComponentPool:removeAllComponents(entityId)
    -- Automatic cleanup through ECS lifecycle
end
```

### 2. Input System Integration
**Current Integration:**
- Direct Task.new() calls from user input
- Manual TaskQueue manipulation

**Required Changes:**
- Update input handlers to use TaskComponentPool
- Replace legacy task creation with ECS component creation
- Maintain same user experience with improved backend

### 3. Render System Integration
**Current Rendering:**
- Direct access to Task object properties
- Manual task state visualization

**Required Changes:**
- Query TaskComponentPool for rendering data
- Update visual indicators to use ECS component states
- Optimize batch rendering for multiple task types

### 4. PathFinder Integration
**Current Dependencies:**
- Direct coupling with MovementTask objects
- Manual path calculation triggering

**Required Changes:**
- Integration with MovementSystem for automatic path updates
- Use ECS events for path recalculation triggers
- Remove direct task object dependencies

## Specific Implementation Tasks

### Files Requiring Updates

#### High Priority (Core Dependencies)
1. **`game/systems/EntityManager.lua`**
   - Remove direct Task/TaskQueue references
   - Add TaskComponentPool cleanup integration
   - Update entity creation to support ECS components

2. **`game/systems/Input.lua`**  
   - Replace Task.new() calls with TaskComponentPool operations
   - Update task creation workflow for ECS compatibility
   - Maintain existing keybinding and input behavior

3. **`game/systems/Render.lua`**
   - Update task visualization to query ECS components
   - Optimize rendering pipeline for component-based data
   - Add visual indicators for ECS-specific task states

#### Medium Priority (Feature Dependencies)
4. **`game/systems/PathFinder.lua`**
   - Remove direct MovementTask dependencies  
   - Integrate with MovementSystem event system
   - Update pathfinding triggers for ECS workflow

5. **`game/components/RightClickMenu.lua`**
   - Update task creation UI to use ECS patterns
   - Maintain existing menu functionality and UX
   - Add support for ECS-specific task configuration

6. **`game/systems/Persistence.lua`** 
   - Add ECS component serialization support
   - Maintain save file compatibility during transition
   - Support both legacy and ECS task storage formats

#### Lower Priority (UI/Polish)
7. **`game/components/BottomBar.lua`**
   - Update task status display for ECS components
   - Show ECS-specific task information (dependencies, pooling stats)
   - Maintain existing UI layout and behavior

8. **`game/systems/MapManager.lua`**
   - Update spatial queries to work with ECS components
   - Optimize performance with component-based lookups
   - Remove legacy Task object spatial references

## Integration Strategy

### Phase 1: Core System Updates
- Focus on EntityManager, Input, and Render systems first
- Ensure basic task creation and execution works through ECS
- Validate no regression in core functionality

### Phase 2: Feature System Updates  
- Update PathFinder and UI components
- Add ECS-specific features and optimizations
- Test advanced functionality (dependencies, complex workflows)

### Phase 3: Polish and Optimization
- Update remaining systems and UI components
- Performance optimization and cleanup
- Documentation and final testing

## Testing Requirements

### System Integration Tests
- Verify each updated system works with both legacy and ECS modes
- Test system interactions and event handling
- Validate performance improvements

### Compatibility Tests
- Ensure save/load compatibility during transition
- Test UI responsiveness and functionality  
- Verify no regression in user experience

## Success Criteria

### Functional Requirements
- [ ] All dependent systems work seamlessly with ECS architecture
- [ ] No functionality regression in updated systems
- [ ] User interface maintains existing behavior and responsiveness
- [ ] Save/load compatibility preserved during migration

### Performance Requirements
- [ ] Rendering performance improved through ECS batch processing
- [ ] Input handling latency maintained or improved
- [ ] Memory usage optimized through reduced object creation

### Code Quality
- [ ] Clean separation between ECS and legacy code paths
- [ ] Consistent error handling across updated systems
- [ ] Comprehensive test coverage for updated functionality

## Risk Mitigation

### Backward Compatibility
- Maintain dual code paths during transition period
- Comprehensive testing of both modes
- Clear rollback strategy if issues arise

### System Complexity
- Update systems incrementally to isolate issues
- Maintain clear interfaces between systems
- Document integration points and dependencies

## Dependencies
- Requires: Subtasks 01-06 (complete ECS integration and testing)
- Enables: Subtask 08 (final optimization with full system integration)

## Estimated Effort
**High** - Extensive system updates requiring careful coordination and testing