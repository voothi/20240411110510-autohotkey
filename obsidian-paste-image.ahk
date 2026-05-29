#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Obsidian ZID Paste Image Hotkey
; Hotkey:       Ctrl + Alt + I (^!i)
;
; Description:  Extracts the exact path of the currently open markdown file from
;               the editor, takes the image from the clipboard, runs paste_image.py
;               to save the image inside the vault with a unique ZID filename, and
;               automatically pastes the formatted Obsidian wikilink back.
;
;               Active-file resolution priority:
;                 1. VS Code / Antigravity IDE "Copy Path" command
;                    Sends Ctrl+Shift+P → "Copy Path" → reads the full absolute path
;                    directly from the editor. Zero guesswork, zero scanning.
;                 2. Full absolute .md path embedded in the window title (rare,
;                    some terminals surface it).
;                 3. Window title passed as --title so paste_image.py can scan
;                    the vault for the matching filename as a last resort.
;
;               For step 1 to work the active window must be VS Code or an Electron
;               editor that exposes the standard command palette (Ctrl+Shift+P) and
;               contains the "Copy Path" command.
;
; Dependencies:
;   - Python 3 must be installed with Pillow and pyperclip.
;   - `paste_image.py` at `U:\voothi\20260529201233-obsidian-paste-image\src\paste_image.py`.
; ===================================================================================

; ---- Helper: ask the editor for the current file path via command palette --------
;  Works for VS Code, Antigravity IDE, and any other Electron editor that exposes
;  workbench.action.copyFilePath (Ctrl+Shift+P → "Copy Path").
;
;  Returns the absolute path string on success, or "" on failure / timeout.
GetEditorFilePath() {
    ; Only attempt for known VS Code / Electron editor processes
    try
        activeExe := WinGetProcessName("A")
    catch
        return ""

    knownEditors := ["antigravity.exe", "code.exe", "cursor.exe", "windsurf.exe"]
    isEditor := false
    for _, exe in knownEditors {
        if (StrLower(activeExe) = exe) {
            isEditor := true
            break
        }
    }
    if !isEditor
        return ""

    ; Save the full clipboard (images, rich text, etc.) so we can restore it
    savedClip := ClipboardAll()
    A_Clipboard := ""

    ; Open command palette and invoke "Copy Path"
    ; Use SendEvent to send raw key events, bypassing AHK's own hotkey layer
    SendEvent("^+p")
    Sleep(350)
    SendEvent("Copy Path{Enter}")

    ; Wait up to 1.2 s for the clipboard to be filled with the file path
    gotClip := ClipWait(1.2)

    candidate := ""
    if gotClip {
        candidate := A_Clipboard
        ; Validate: must be an absolute Windows path to a markdown file
        if !RegExMatch(candidate, "^[A-Za-z]:\\.+\.md$")
            candidate := ""
    }

    ; Restore whatever was in the clipboard before
    A_Clipboard := savedClip

    return candidate
}

; ==================================================================================

^!i::
{
    activeTitle := WinGetTitle("A")

    ; ---- 1. Ask the editor directly (most reliable) ------------------------------
    activeFile := GetEditorFilePath()

    ; ---- 2. Fallback: try to parse a full absolute path from the window title ----
    if (activeFile = "") {
        if RegExMatch(activeTitle, "([A-Za-z]:\\[^\x00-\x1F`"*<>?|]+\.md)", &mFile)
            activeFile := mFile[1]
    }

    ; ---- 3. Extract ZID-prefixed workspace token from the title -----------------
    workspace := ""
    if RegExMatch(activeTitle, "(\d{14}-[\w-]+)", &mWs)
        workspace := mWs[1]

    ; ---- Build command -----------------------------------------------------------
    ;  --active-file   exact path if we obtained it (steps 1 or 2)
    ;  --title         full window title; Python scans the vault as last resort
    ;  --workspace     ZID token; Python infers the project assets directory
    cmd := "C:\Python\Python312\python.exe U:\voothi\20260529201233-obsidian-paste-image\src\paste_image.py"

    if (activeFile != "")
        cmd .= " --active-file `"" . activeFile . "`""

    if (activeTitle != "")
        cmd .= " --title `"" . activeTitle . "`""

    if (workspace != "")
        cmd .= " --workspace `"" . workspace . "`""

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
