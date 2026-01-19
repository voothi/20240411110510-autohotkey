20260119163141

# 20260119163141 - Fix Hotkey Parameter Error

## Request
Error when trying to translate using a keyboard shortcut.
`Error: Too many parameters passed to function.`

## Staging
Update `tts.ahk` to handle the additional parameter passed by the `Hotkey` command when using bound functions.

## Implementation Details

### Analytics
- The user encounters a "Too many parameters" error when triggering a TTS hotkey (e.g., `^!+4`).
- In `tts.ahk`, hotkeys are registered dynamically using `Hotkey(info.hotkey, RunPythonScript.Bind(code))`.
- In AutoHotkey v2, the callback function for a `Hotkey` receives the hotkey name as a parameter.
- Because we used `.Bind(code)`, the `code` becomes the first argument, and the hotkey name becomes the second argument.
- The function `RunPythonScript(lang := "")` is defined to accept at most one argument.
- When called via the hotkey, it receives two arguments: `(code, ThisHotkey)`, causing the error.

### Decisions
- Modify the `RunPythonScript` function signature to `RunPythonScript(lang := "", *)`.
- The `*` (variadic parameter) allows the function to accept any number of additional arguments (like `ThisHotkey`) without throwing an error.
