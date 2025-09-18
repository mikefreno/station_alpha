# 04. Correct Flex Direction Handling Logic

meta:
  id: gui-layout-css-issues-04
  feature: gui-layout-css-issues
  priority: P2
  depends_on: [gui-layout-css-issues-03]
  tags: [implementation, layout, fixes]

objective:
- Fix the flex direction handling logic in layoutChildren function
- Ensure proper positioning for both horizontal and vertical flex layouts
- Correct alignment calculations based on flex direction

deliverables:
- Corrected layoutChildren function with proper flex direction logic
- Horizontal and vertical layouts position children correctly 
- Alignment properties properly applied based on flex direction
- Cross-axis and main-axis calculations work correctly

steps:
- Examine the flex direction handling in layoutChildren (lines 599-767)
- Fix incorrect positioning logic for horizontal vs vertical directions
- Correct how alignment is applied for cross-axis vs main-axis
- Ensure margin and padding are handled properly for each direction
- Validate that both flexDirection values work correctly

tests:
- Unit: Run flex-direction-tests.lua to verify flex direction handling
- Integration: Test with different alignment modes (alignItems, alignSelf)
- Integration: Test with various child configurations for both directions
- E2E: Complete layout tests with mixed flex directions

acceptance_criteria:
- Horizontal flex layouts position children correctly along x-axis
- Vertical flex layouts position children correctly along y-axis
- Alignment properties work correctly for both directions
- Cross-axis alignment is applied to correct axis based on flex direction
- No more failing tests due to incorrect flex direction logic

validation:
- Run flex-direction-tests.lua after implementing fixes
- Verify horizontal and vertical layouts behave as expected
- Test with different alignment combinations for both directions
- Compare behavior with CSS flexbox specification

notes:
- The current implementation incorrectly handles positioning for vertical flex direction
- Alignment logic needs to be direction-aware (cross-axis vs main-axis)
- Margin and padding application varies based on flex direction