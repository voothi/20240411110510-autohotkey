# 20251224202917 - Google AI Studio Deletion Hotkey

*   **Status**: Implemented
*   **Date**: 2025-12-24
*   **Related ZIDs**: `20251224203846` (Return Cursor), `20251224204050` (Loop Action)

## Context
The user requested a way to quickly delete items in the Google AI Studio interface (`aistudio.google.com`). The native UI requires clicking a "three-dots" menu and then selecting "Delete" from the dropdown. Doing this repeatedly for multiple items is tedious.

## Requirements
1.  **Trigger**: `Alt + Left Click` on the menu button.
2.  **Action**: Automatically click the menu, move the mouse to the "Delete" option, and click it.
3.  **Cursor Behavior**: The mouse cursor should appear to return to the starting position (or stay relatively stable) so the user doesn't lose their place.
4.  **Repetition**: Holding the button should repeat the action to allow "painting" deletions across a list.

## Implementation Details

### Hotkey Logic
The script uses `Alt+LButton` (`!LButton`) to trigger the sequence.

### Automation Sequence
1.  **Loop**: The script enters a `While` loop checking `GetKeyState("LButton", "P")` to support holding the button for repeated actions.
2.  **State Capture**: Inside the loop, `MouseGetPos &X, &Y` captures the current cursor position. This is critical to be *inside* the loop so that if the user moves the mouse between iteration pauses, the return position updates to the new location.
3.  **Action**:
    *   `Send "{Click}"`: Opens the menu.
    *   `MouseMove 50, 50, 0, "R"`: Moves diagonally relative to the current position to hit the "Delete" button. The offset `50, 50` was determined experimentally.
    *   `Send "{Click}"`: Executes the delete.
4.  **Restoration**: `MouseMove X, Y`: Immediately returns the cursor to the original position (the menu button location) to prepare for the next action or simply purely for user comfort.
5.  **Timing**: `Sleep 400` at the end of the loop prevents the actions from firing too rapidly for the UI to handle.

### Code Snippet
```autohotkey
; Alt+LeftClick to delete item: Click, move diagonal 10px, click again.
!LButton::
{
    while GetKeyState("LButton", "P") {
        MouseGetPos &X, &Y
        Send "{Click}"
        Sleep 100
        MouseMove 50, 50, 0, "R"
        Sleep 100
        Send "{Click}"
        MouseMove X, Y
        Sleep 400
    }
}
```
