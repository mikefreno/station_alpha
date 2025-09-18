# 02. Fix Child Element Dimension Initialization

meta:
  id: gui-layout-css-issues-02
  feature: gui-layout-css-issues
  priority: P2
  depends_on: [gui-layout-css-issues-01]
  tags: [implementation, layout, fixes]

objective:
- Ensure child elements properly initialize their width and height properties
- Fix the Element.new() function to correctly set dimension values for children
- Ensure dimensions are calculated properly during element creation

deliverables:
- Modified FlexLove.lua with corrected element initialization logic
- Child elements now have proper width/height fields set during creation
- Fixed auto-sizing calculations that depend on child dimensions

steps:
- Review Element.new() function in FlexLove.lua to identify where dimensions are set
- Analyze how width/height properties should be initialized for children 
- Fix the logic that determines when to calculate auto-width/height vs use provided values
- Ensure that child elements get their width/height properly set during addChild()
- Validate that dimension calculations work correctly for all element types

tests:
- Unit: Run justify-content-tests.lua after fix to see if nil errors are resolved
- Unit: Run flex-direction-tests.lua after fix to see if layout positioning works 
- Unit: Run absolute-positioning.lua after fix to see if absolute positioning works
- Integration: Test nested layouts with dimension validation

acceptance_criteria:
- Child elements have width and height properties set during creation
- No more nil value errors when accessing child.width or child.height
- Auto-sizing calculations work correctly for elements without explicit dimensions
- All layout tests pass without failing on dimension access errors

validation:
- Run the individual test files to verify fixes work
- Check that element properties are properly initialized in Element.new()
- Verify that addChild() properly sets up child dimensions
- Test with various element configurations (with/without explicit sizes)

notes:
- The core problem appears to be that children don't get width/height set during creation
- This causes layoutChildren() to fail when accessing child.width or child.height
- Need to ensure both parent and child elements properly initialize their dimensions