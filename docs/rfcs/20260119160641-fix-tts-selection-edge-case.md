20260119160641

# 20260119160641 - Fix TTS Selection Edge Case

## Request
It is necessary to try to identify and solve the edge case when the user switches in the mode without lifting the left mouse button pressed several times by moving the pointer over the words, reducing the substring selection area and pressing the middle key (wheel) again at this moment. Now it seems to work every other time. I think due to the lack of a pressed key.

## Staging
Address the issue where triggering TTS via the mouse combination (~LButton & MButton) fails intermittently when used repeatedly during selection adjustments.

## Implementation Details

### Analytics
- The user reports an "every other time" failure when repeatedly triggering the TTS function while adjusting text selection with the left mouse button held down.
- The current implementation uses `RunWait` to execute the Python script.
- `RunWait` blocks the AutoHotkey thread until the external process (TTS playback) completes.
- If the user triggers the hotkey again while the previous TTS is still playing (and thus the script is waiting), the new hotkey event is ignored because the maximum number of threads per hotkey is 1 by default, and the current thread is blocked.
- This blocking behavior aligns with the description of working intermittently (likely succeeding only after the previous audio has finished).

### Decisions
- Change `RunWait` to `Run` in `tts.ahk`. This ensures the AutoHotkey thread finishes immediately after launching the Python script, allowing subsequent triggers to be processed even if the audio is still playing.
- This change allows the user to "interrupt" (visually/logically) their workflow and trigger a new TTS command without waiting for the previous one to finish. Note: The previous audio might continue playing in the background depending on how the Python script handles it (e.g., if it uses a non-blocking player or if multiple instances run in parallel). This is preferable to the command being ignored.
