# Station Alpha

A tile-based colony strategy game built with Lua and LÖVE 2D. Currently in the scaffolding stage, currenly, this project implements a pathfinding system, entity management, and a grid-based map with different terrain types.

## Project Structure

```
.git/
build/
game/
├── components/        # Game entities and their properties
│   ├── Camera.lua
│   ├── LoadingIndicator.lua
│   ├── MoveTo.lua
│   ├── PauseMenu.lua
│   ├── RightClickMenu.lua
│   ├── Schedule.lua
│   ├── Shape.lua
│   ├── TaskQueue.lua
│   ├── Texture.lua
│   ├── Tile.lua
│   └── Topography.lua
├── libs/              # 'Third' party libraries 
│   ├── Cartographer.lua
│   ├── MyGUI.lua      # A UI Lib I am developing
│   └── OverlayStats.lua
├── runtime/           # Native libraries for HTTPS support
├── systems/           # Game logic and systems
│   ├── EntityManager.lua
│   ├── Input.lua
│   ├── MapManager.lua
│   ├── PathFinder.lua
│   ├── Persistence.lua
│   ├── Position.lua
│   ├── Render.lua
│   └── TaskManager.lua
├── utils/             # Utility functions and data structures
│   ├── Vec2.lua
│   ├── constants.lua
│   ├── enums.lua
│   └── helperFunctions.lua
├── runtime/           # Runtime libraries
│   └── https/
├── main.lua           # LÖVE entrypoint 
├── conf.lua           # LÖVE configuration
└── logger.lua         # Logging system
resources/
testing/
├── __tests__/         # Tests for various components or systems
│   ├── mygui.lua
│   └── pathfiner.lua
└── luaunit.lua        # Testing lib
tools/                 # Tools for building, installing dependencies, et
├── build-love.sh
├── build.sh
├── context.sh
├── install.sh
└── test-html.sh
.editorconfig
.gitignore
.luarc.json
.stylua.toml
flake.lock
flake.nix
README.md
USAGE.md
```

## Core Concepts

### Entity Component System (ECS)
The game uses an Entity Component System architecture where:
- Entities are just IDs with no data
- Components hold the data for entities
- Systems process components to create behavior

### Map System
- 100x75 grid map (logical units)
- Each tile is 32 pixels in size by default
- Three terrain types: Open, Rough, and Inaccessible
- Pathfinding implemented with A* algorithm

### Key Features
- Click-to-move functionality for entities
- Camera system with zoom support
- Dynamic pathfinding
- Terrain-based movement speed modifiers
- Right-click menu system
- Loading indicators during map generation

## How to Run

1. Install required dependencies by running:
   ```
   ./tools/install.sh
   ```

2. Build the project:
   ```
   ./tools/build.sh
   ```

3. Run the game:
   ```
   love game/
   ```

## Controls
- Left-click: Move selected entity to clicked position
- Right-click: Show context menu
- F3: Show OverlayStats (fps etc.)
- Ctrl+~: Show Logger
- Mouse wheel: Zoom in/out (with ctrl, to scroll logger)

## Dependencies
- LÖVE 2D (https://love2d.org/)
- Lua 5.1 or higher
