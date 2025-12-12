# TODO

## Feature Request: Package-Aware Analysis for Neovim Revive Plugin

Problem

The Neovim plugin currently runs revive-rules on individual files, which causes false positives for map type aliases defined in other files within the same package.
Example False Positive:
// In utils.go (same package)
type MsgIdToRequestOutOfBridge map[string]*RequestOutOfBridge
// In sui.go (being analyzed)
func foo() {
    requests := make(MsgIdToRequestOutOfBridge)
    requests["key"] = value  // ❌ FALSE POSITIVE: flagged as slice access
}
Root Cause
When analyzing a single file in isolation, the slice-access-check rule cannot detect map type aliases defined in other files of the same package. The rule requires package-level context to scan all files for type definitions.
Proposed Solution
Modify the plugin to run revive-rules on the package directory instead of individual files.
Current behavior:
revive-rules /path/to/current/file.go  # Single file - limited context
Desired behavior:
cd /path/to/package && revive-rules .  # Package directory - full context
Implementation Considerations
1. Determine package directory: 
   - Find the directory containing the current buffer's file
   - Verify it contains a Go package (has *.go files with same package name)
2. Run analysis on package:
   - Execute revive-rules . from the package directory
   - Or pass the package directory as argument: revive-rules /path/to/package
3. Filter diagnostics:
   - Parse the full JSON output from all package files
   - Filter to only show diagnostics for the current buffer's file
   - Preserve line/column numbers for accurate placement
4. Performance optimization:
   - Cache package-level analysis results
   - Only re-run when package files change (not just current file)
   - Consider debouncing to avoid re-analyzing on every keystroke
5. Handle edge cases:
   - Test files (*_test.go) are part of the package
   - Main package files
   - Files in subdirectories (sub-packages)
   - Symlinks and workspace configurations
Benefits
- ✅ Eliminates false positives for cross-file type aliases
- ✅ More accurate analysis (matches how go build works)
- ✅ Better developer experience with fewer spurious warnings
- ✅ Consistent with Go's package-based compilation model
Alternative Approaches
Option A: Package-aware mode (recommended)
- Always analyze at package level
- Filter results to current file
Option B: Hybrid mode
- Analyze single file for fast feedback
- Periodically run package analysis in background
- Merge/deduplicate results
Option C: Configuration option
- Add setting to toggle between file-level and package-level analysis
- Let users choose based on their workflow preferences
Expected Outcome
The plugin should provide the same analysis results whether using the CLI directly (revive-rules .) or through the Neovim integration, eliminating false positives caused by incomplete type information.
