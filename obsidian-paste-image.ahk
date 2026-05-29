#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Obsidian ZID Paste Image Hotkey
; Hotkey:       Ctrl + Alt + I (^!i)
;
; Description:  Extracts the active workspace title, takes the image from the
;               clipboard, runs paste_image.py in the background to save the
;               image inside the project vault with a unique ZID filename, and
;               automatically pastes the formatted wikilink back into the editor.
;
; Dependencies:
;   - Python 3 must be installed with Pillow.
;   - `paste_image.py` at `U:\voothi\20260529201233-obsidian-paste-image\src\paste_image.py`.
; ===================================================================================

^!i::
{
    ; Extract the active window title to parse the workspace (e.g., 20260308110646-kardenwort-mpv)
    activeTitle := WinGetTitle("A")
    workspace := ""
    if RegExMatch(activeTitle, "(\d{14}-[\w-]+)", &match) {
        workspace := match[1]
    }

    ; Call paste_image.py to extract image from clipboard, save in vault, and write back wikilink
    cmd := "C:\Python\Python312\python.exe U:\voothi\20260529201233-obsidian-paste-image\src\paste_image.py"
    if (workspace != "") {
        cmd .= " --workspace `"" . workspace . "`""
    }
    if (activeTitle != "") {
        cmd .= " --title `"" . activeTitle . "`""
    }

    ; RunWait pauses execution until the script finishes.
    ; The "Hide" option keeps it silent and fast in the background.
    RunWait(cmd, "U:\voothi\20260529201233-obsidian-paste-image", "Hide")
    
    ; Pause for system-specific clipboard update delay
    Sleep(300)

    ; CRITICAL Safeguard (Modifier Bleed Prevention):
    ; Wait for the user to physically release Alt and Control
    KeyWait "Alt"
    KeyWait "Control"

    ; Paste the formatted wikilink back, replacing the selection.
    Send("^v")
}
