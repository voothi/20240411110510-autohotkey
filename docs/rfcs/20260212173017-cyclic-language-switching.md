# RFC - Cyclic Language Switching in `tts.ahk`

**ZID**: 20260212173017

## Status
- **Staging**: [approved]
- **Release**: v1.48.24

## User Request
The user requested the ability to switch between languages in `tts.ahk` by repeatedly pressing the Middle Mouse Button (MButton) while holding the Left Mouse Button (LButton). The switching should be cyclic and occur if the button is pressed again within a configurable time window (default 500ms).

## Implementation Details

### Analytics & Decisions
1.  **Hotkey selection**: Using `~LButton & MButton`. The `~` prefix ensures the Left Button click isn't swallowed, preserving standard text selection behavior.
2.  **Timing Logic**: 
    - A standard single click should still trigger text-to-speech.
    - To distinguish between "Play" and "Cycle", we implement a delay for the "Play" action.
    - `A_PriorHotkey` and `A_TimeSincePriorHotkey` are used to detect rapid successive presses of the Middle Button.
    - If a rapid press is detected, the pending "Play" timer is cancelled, and the language is cycled.
3.  **Configurability**:
    - Users have different physical click speeds. A `DoublePressDelay` setting was added to `config.ini` (default 500ms).
4.  **Language Order**:
    - The cycle follows the exact order of keys in the `[Languages]` section of `config.ini`.
5.  **Testability**:
    - The script was refactored to wrap initialization in `InitializeTTS()` and use an execution guard.
    - A `RunExternal` delegate was introduced to allow for mocking the `Run` command in v2, where redefinition of built-in functions is prohibited.

### Changes
- **`tts/tts.ahk`**: Refactored for testability, added `CycleLanguage()`, implemented timer-based hotkey logic.
- **`tts/config.ini`**: Added `DoublePressDelay` setting.
- **`tests/test_tts.ahk`**: Consolidated unit and regression test suite.

## Verification Result
Tests passed in `test_tts.ahk` (merged suite).
Manual verification confirmed:
- Holding LButton and clicking MButton once -> Playback starts after 500ms.
- Holding LButton and clicking MButton twice -> Language cycles, no playback.
