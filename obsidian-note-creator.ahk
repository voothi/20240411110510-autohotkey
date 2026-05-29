#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Obsidian ZID Note Creator Hotkey
; Hotkey:       Ctrl + Alt + K (^!k)
;
; Description:  Copies selected text (which starts with or contains ZID lines),
;               calls note_creator.py to batch create notes exactly 1-to-1,
;               updates the active conversation log MOC, copies the formatted
;               Obsidian wikilinks back to the clipboard, and pastes them.
;
; Dependencies:
;   - Python 3 must be installed.
;   - Pyperclip must be installed in Python.
;   - `note_creator.py` at `U:\voothi\20260529182202-obsidian-note-creator\src\note_creator.py`.
; ===================================================================================

^!k::
{
    ; Extract the active window title to parse the workspace (e.g., 20260308110646-kardenwort-mpv)
    activeTitle := WinGetTitle("A")
    workspace := ""
    if RegExMatch(activeTitle, "(\d{14}-[\w-]+)", &match) {
        workspace := match[1]
    }

    ; Step 1: Copy the selected text to system clipboard.
    Send("^c")
    if !ClipWait(1.5) ; Wait up to 1.5 seconds for clipboard content
    {
        MsgBox("Clipboard copy failed or timed out.", "Error", 16)
        return
    }

    ; Step 2: Run the note creator script with the --clipboard flag.
    cmd := "C:\Python\Python312\python.exe U:\voothi\20260529182202-obsidian-note-creator\src\note_creator.py --clipboard"
    if (workspace != "") {
        cmd .= " --workspace `"" . workspace . "`""
    }

    ; RunWait pauses execution until the script finishes.
    ; The "Hide" option keeps it silent and fast in the background.
    RunWait(cmd, "U:\voothi\20260529182202-obsidian-note-creator", "Hide")
    
    ; Pause for system-specific clipboard update delay
    Sleep(300)

    ; CRITICAL Safeguard (ZID: 20260515102336):
    ; Wait for the user to physically release Alt and Control to prevent Modifier Bleed.
    KeyWait "Alt"
    KeyWait "Control"

    ; Step 3: Paste the formatted wikilinks back, replacing the selection.
    Send("^v")
}
