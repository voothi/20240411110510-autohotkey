## 1. Implement Modifier-Safe Utility in Clipboard Library

- [ ] 1.1 Implement `WaitForModifiers()` function in `Lib\ClipboardUtil.ahk` to query and wait for physical modifiers (`Ctrl`, `Alt`, `Shift`, `Win`).
- [ ] 1.2 Update `SmartCopy` signature and body to call `WaitForModifiers()` based on the `shouldWait := true` parameter. Ensure no case-insensitive shadowing conflicts occur.

## 2. Refactor Dictionary Hotkeys to Unified Abstraction

- [ ] 2.1 Refactor `gd-main.ahk` (`^!+1`) to call unified `SmartCopy(3)` instead of raw clipboard clears and simulated keystrokes.
- [ ] 2.2 Refactor `gd-side.ahk` (`^!+q`) to call unified `if SmartCopy(3)` instead of raw clipboard clears and simulated keystrokes.

## 3. Verification

- [ ] 3.1 Reload active background AutoHotkey scripts.
- [ ] 3.2 Verify that `Ctrl+Alt+Shift+1` and `Ctrl+Alt+Shift+Q` do not cause modifier leakage or false hotkey triggers (e.g. Chrome Developer Tools).
