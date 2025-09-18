# 03. Implement Proper Justify Content Algorithms

meta:
  id: gui-layout-css-issues-03
  feature: gui-layout-css-issues
  priority: P2
  depends_on: [gui-layout-css-issues-02]
  tags: [implementation, layout, algorithms]

objective:
- Correct the justify-content calculation logic in layoutChildren function
- Implement proper spacing calculations for all justify-content values
- Ensure flex direction correctly affects how spacing is applied

deliverables:
- Fixed layoutChildren function with correct justify-content algorithms
- Proper handling of FLEX_START, CENTER, FLEX_END, SPACE_AROUND, SPACE_EVENLY, SPACE_BETWEEN
- Correct margin and padding application for spacing calculations

steps:
- Review the existing justify-content logic in layoutChildren function (lines 571-589)
- Fix incorrect spacing calculation for different justify-content values
- Ensure proper handling of margin and padding in available space calculations  
- Correct the algorithm to properly distribute space according to CSS flexbox spec
- Validate that all justify-content modes work correctly for both directions

tests:
- Unit: Run justify-content-tests.lua to verify all justify-content modes work
- Integration: Test with different flex directions (horizontal/vertical)
- Integration: Test with various child counts and sizes
- E2E: End-to-end test of complete layout scenarios

acceptance_criteria:
- All justify-content values (FLEX_START, CENTER, FLEX_END, SPACE_AROUND, SPACE_EVENLY, SPACE_BETWEEN) work correctly
- Proper spacing distribution according to CSS flexbox specification
- Flex direction properly affects the calculation and application of spacing
- No more failing tests due to incorrect spacing logic

validation:
- Run justify-content-tests.lua after implementing fixes
- Verify each justify-content mode produces expected results  
- Test with different child configurations to ensure robustness
- Compare output with expected CSS flexbox behavior

notes:
- The current implementation has incorrect spacing calculations for most justify-content modes
- SPACE_AROUND, SPACE_EVENLY, and SPACE_BETWEEN need proper distribution logic
- Need to account for margins and padding in available space calculation