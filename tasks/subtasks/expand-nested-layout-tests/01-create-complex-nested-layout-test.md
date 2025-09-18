# 01. Create Complex Nested Layout Test Cases

meta:
  id: expand-nested-layout-tests-01
  feature: expand-nested-layout-tests
  priority: P2
  depends_on: []
  tags: [testing, layout]

objective:
- Create comprehensive test cases for complex nested layouts in FlexLove

deliverables:
- New test file: game/libs/testing/complex-nested-layouts.lua
- Test cases covering multiple nesting scenarios

steps:
- Create new test file complex-nested-layouts.lua
- Implement test cases for:
  - Deep nesting (3+ levels) with varying flex properties
  - Mixed horizontal and vertical layouts
  - Dynamic size calculations across nested levels
  - Complex alignment scenarios with nested children
  - Edge cases for nested container sizing
- Add setup and teardown functions for test isolation
- Document each test case with clear descriptions

tests:
- Unit:
  - Test nested container creation
  - Verify size calculations
  - Validate child positioning
  - Check alignment inheritance
- Integration:
  - Full layout rendering validation
  - Cross-component interaction tests

acceptance_criteria:
- All test cases pass successfully
- Test coverage includes scenarios with 3+ levels of nesting
- Each test case has clear documentation explaining the layout structure
- Test setup/teardown properly cleans up between tests
- No test case duplicates existing simple layout tests

validation:
- Run: lua testing/__tests__/complex-nested-layouts.lua
- Verify all tests pass
- Check test output for proper setup/teardown
- Review test coverage report

notes:
- Reference FlexLove documentation for layout specifications
- Use love_helper.lua for LÖVE framework stubs
- Consider performance implications of deeply nested structures