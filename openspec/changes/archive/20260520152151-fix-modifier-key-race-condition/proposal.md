## Why

When complex hotkeys utilizing multiple modifiers (such as `Ctrl + Alt + Shift + 1` or `Ctrl + Alt + Shift + Q`) are triggered, the logical release/restore of modifier keys performed automatically by AutoHotkey to send `Ctrl+C` causes a timing race condition with physical key releases. This leads to the keystroke "decomposing" and false-triggering other application-level hotkeys (e.g., Chrome Developer Tools `Ctrl+Shift+C`).

## What Changes

- **Physical Modifier release check**: Introduce a `WaitForModifiers()` helper in `Lib\ClipboardUtil.ahk` to query physical modifier key states (`Ctrl`, `Alt`, `Shift`, `Win`) and halt execution until they are physically released.
- **Unified Abstraction Integration**: Refactor key active lookup scripts (`gd-main.ahk` and `gd-side.ahk`) to utilize the unified `SmartCopy()` copy abstraction, securing them with physical modifier state verification.
- **Shadowing Resolution**: Ensure the `SmartCopy` parameter does not conflict with the function name `WaitForModifiers()` due to AutoHotkey's case-insensitivity.

## Capabilities

### New Capabilities

### Modified Capabilities
- `unified-clipboard-abstraction`: Update the clipboard abstraction layer requirements to mandate physical modifier key release waiting during copy sequences to guarantee race-free hotkey operation.

## Impact

- **Affected Files**: `Lib\ClipboardUtil.ahk`, `gd-main.ahk`, `gd-side.ahk`
- **Dependencies**: AutoHotkey v2 runtime environments
