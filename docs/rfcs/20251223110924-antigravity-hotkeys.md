# 20251223110924 - Antigravity Hotkeys

## Summary
Add similar behavior of pressing Enter for the Antigravity.exe application to the script `hotkeys.ahk`.

## Context
Original Request:
> Add to the script @hotkeys.ahk another similar behavior of pressing Enter for the Antigravity.exe application

## Implementation Details
- Remapped `Enter` to `Shift+Enter` (New Line) for `ahk_exe Antigravity.exe`.
- Initially mapped `Ctrl+Enter` to `Enter` (Submit), but this conflicted with the Commit shortcut in Antigravity.
- **Refinement**: Removed `Ctrl+Enter` remapping for Antigravity to restore native Commit functionality.
- **Refinement**: Removed `Shift+Enter` remapping for Antigravity to allow native New Line behavior in Chat (user preference changed).
- Final state for Antigravity:
    - `Enter` -> `Shift+Enter` (New Line)
    - `Ctrl+Enter` -> Native (Commit)
    - `Shift+Enter` -> Native (New Line)
