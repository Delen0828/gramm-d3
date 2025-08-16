---
description: Debug Vega JS files and fix MATLAB export_vega.m based on the debug output
allowed-tools: Bash(*), Edit
---

# Debug Vega JS File

Debug the Vega/Vega-Lite JavaScript file: `$ARGUMENTS` and modify the code in the corresponding MATLAB export_vega.m functions.

## Analysis Process

1. **Read and analyze the target JS file** for syntax errors, structural issues, and common Vega problems
2. **Identify specific issues** including:
   - Syntax errors and malformed JSON
   - Missing required Vega-Lite schema elements
   - Undefined data references
   - Scale domain configuration errors
   - Mark and encoding specification problems
   - Data transformation issues

3. **Map each issue to specific MATLAB fixes** in export_vega.m:
   - Identify which MATLAB functions generate the problematic JS code
   - Provide concrete code changes for the MATLAB generation logic
   - Suggest validation checks to prevent similar issues

4. **Implement the fix in MATLAB files** including:
   - Priority order for fixes (critical → high → medium → low)
   - For each fix find them in @gramm/export_vega.m and fix them based on the plans

## Output Format

Provide a structured report with:
- **Executive Summary**: Brief overview of issues found
- **Detailed Issues**: Each problem with severity level and MATLAB fix
- **Next Steps**: Specific actions to take in export_vega.m
- **Code Fix**: implementing fixes in export_vega.m

## Usage Examples

- `/jsdebug /path/to/vega_file.js TEXT` - Debug file with full path with error feedback TEXT

**Important**: This command analyzes the JS file and suggests MATLAB fixes. You'll need to manually apply the suggested changes to export_vega.m and regenerate the JS file for testing.