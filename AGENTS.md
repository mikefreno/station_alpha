# AGENTS.md

## Build/Lint/Test Commands
- Build: `./tools/build.sh`
- Install dependencies: `./tools/install.sh`
- Run single test: `lua testing/__tests__/<file_name>.lua`
- Style: `stylua --check <file_name>.lua`
- Linting: `lua-language-server --check <file_name>.lua`

## Code Style Guidelines
- Lua formatting with stylua (2-space indent, Unix line endings)
- Import order: utils, components, systems, libs
- Naming conventions: PascalCase for classes, snake_case for functions and variables
- Error handling: use Logger:error() for logging errors
- Function documentation: use @param and @return annotations
- File structure: each component in its own file under game/components/
- Use `@type` annotations for type hints where applicable
- Ensure all files end with a newline

## Additional Info
- All game related files are within the game directory
- The GUI Library 'FlexLove' is fine to edit
- game/libs is a git submodule
- When writing tests that depend upon `love` import the stub file: testing/love_helper.lua, expand it if necessary.
- You can check the README.md for more information
