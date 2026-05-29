#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Obsidian ZID Paste Image Hotkey
; Hotkey:       Ctrl + Alt + I (^!i)
;
; Description:  Extracts the active workspace title and open file path, takes the
;               image from the clipboard, runs paste_image.py to save the image
;               inside the vault with a unique ZID filename, and automatically
;               pastes the formatted Obsidian wikilink back into the editor.
;
;               Active-file resolution priority (mirrors paste_image.py logic):
;                 1. Full absolute .md path embedded in the window title
;                    → passed as --active-file (zero-scan, classic relative link)
;                 2. .md filename found anywhere in the window title
;                    → passed as --title (vault scan)
;                 3. ZID-prefixed workspace token from the window title
;                    → passed as --workspace (project-level assets fallback)
;
; Dependencies:
;   - Python 3 must be installed with Pillow and pyperclip.
;   - `paste_image.py` at `U:\voothi\20260529201233-obsidian-paste-image\src\paste_image.py`.
; ===================================================================================

^!i::
{
    activeTitle := WinGetTitle("A")

    ; ---- 1. Try to extract a full absolute .md path from the title ---------------
    ;  Terminals, some IDEs, and the system title bar can surface the full path.
    activeFile := ""
    if RegExMatch(activeTitle, "([A-Za-z]:\\[^\x00-\x1F""*<>?|]+\.md)", &mFile) {
        activeFile := mFile[1]
    }

    ; ---- 2. Try to extract just the .md filename --------------------------------
    mdFilename := ""
    if (activeFile = "") {
        if RegExMatch(activeTitle, "([\w-]+\.md)\b", &mName) {
            mdFilename := mName[1]
        }
    }

    ; ---- 3. Extract ZID-prefixed workspace token from the title -----------------
    workspace := ""
    if RegExMatch(activeTitle, "(\d{14}-[\w-]+)", &mWs) {
        workspace := mWs[1]
    }

    ; ---- Build command -----------------------------------------------------------
    cmd := "C:\Python\Python312\python.exe U:\voothi\20260529201233-obsidian-paste-image\src\paste_image.py"

    if (activeFile != "") {
        cmd .= " --active-file `"" . activeFile . "`""
    } else if (mdFilename != "") {
        cmd .= " --title `"" . mdFilename . "`""
    }

    if (activeTitle != "") {
        ; Always pass the full title so the Python script can do its own parsing
        cmd .= " --title `"" . activeTitle . "`""
    }

    if (workspace != "") {
        cmd .= " --workspace `"" . workspace . "`""
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
