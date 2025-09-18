# 05. Fix Absolute Positioning Calculations

meta:
  id: gui-layout-css-issues-05
  feature: gui-layout-css-issues
  priority: P2
  depends_on: [gui-layout-css-issues-04]
  tags: [implementation, layout, fixes]

objective:
- Correct absolute positioning logic in layoutChildren function
- Ensure absolute children maintain their coordinates properly
- Fix handling of absolute positioned elements within flex containers

deliverables:
- Fixed layoutChildren to properly handle absolute positioned children
- Absolute children retain their positions relative to parent container
- Mixed absolute and flex children work correctly together
- Proper skip logic for absolute child positioning

steps:
- Examine the absolute positioning logic in layoutChildren (lines 594-597)
- Fix the "goto continue" logic that skips positioning for absolute children
- Ensure absolute children don't interfere with flex layout calculations
- Validate that absolute positioning works correctly within nested containers
- Test with mixed layouts containing both absolute and flex children

tests:
- Unit: Run absolute-positioning.lua to verify absolute positioning works
- Integration: Test nested structures with absolute positioned elements
- Integration: Test with flex children alongside absolute children
- E2E: Complete test of complex layouts with absolute positioning

acceptance_criteria:
- Absolute positioned children maintain their coordinates correctly
- Flex layout calculations unaffected by absolute children
- Mixed layouts work properly with both positioning types
- No more failing tests due to incorrect absolute positioning handling

validation:
- Run absolute-positioning.lua after implementing fixes
- Verify absolute child positions are preserved
- Test that flex children still get proper positioning
- Validate complex nested scenarios with absolute elements

notes:
- The current logic has an issue with how absolute children are handled 
- Absolute children should not be positioned by flex layout but also not interfere with calculations
- Need to ensure the skip logic works properly without breaking other functionality