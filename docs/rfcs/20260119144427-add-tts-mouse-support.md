20260119144427

# 20260119144427 - Add TTS mouse support

## Request
20260119140913-add-to-tts-ahk-a

## Staging
Add to tts.ahk a function to call by pressing the middle mouse button (wheel) while selecting text with the left mouse button by moving the pointer along the line to the end of the selection.

## Implementation Details

### Analytics
- Current `tts.ahk` uses keyboard shortcuts to trigger TTS for English, German, Russian, and Ukrainian.
- Users want to use the mouse for a more streamlined experience, especially when sticking to one language.
- Middle mouse button (MButton) is a good candidate for triggering the action during a left-click drag (selection).
- Language selection needs to be persisted or remembered.

### Decisions
1. **Language Persistence**: Store the last used language from a keyboard shortcut in a global variable or environment variable.
2. **Mouse Trigger**: Use a combination of `LButton` and `MButton`. Specifically, if `MButton` is pressed while `LButton` is held down, it should trigger the TTS for the current selection.
3. **Tray Menu**: Enhance the tray menu of `tts.ahk` to allow selecting and displaying the current language.
4. **Environment variable**: Use an environment variable or a local variable within the script to store the current language. Given it's a single script, a global variable in the script (which is persistent) should suffice for the session. For persistence across restarts, an `.ini` file or environment variable might be better. The user mentioned environment variables as a possibility.
5. **Auto-updating current language**: When a specific language hotkey is pressed (e.g., `^!+2` for "en"), update the "current" language to "en".

### Implementation Plan
- Add a global variable `currentLang` defaulting to "en".
- Update `RunPythonScript` to update `currentLang`.
- Add a hotkey for `MButton` that checks if `LButton` is down.
- Update tray menu to show current language.
