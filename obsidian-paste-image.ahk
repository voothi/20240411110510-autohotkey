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
;               A ToolTip confirms the saved path on success, or shows the
;               error line on failure. Auto-dismisses after 4 seconds.
;
;               Active-file resolution priority:
;                 1. Full absolute .md path embedded in the window title.
;                 2. Optional editor "Copy Path" probe (disabled by default).
;                 3. Window title passed as --title so paste_image.py can scan
;                    only inside scoped workspace vault project.
;
; Dependencies:
;   - Python 3 must be installed with Pillow and pyperclip.
;   - `paste_image.py` at `U:\voothi\20260529201233-obsidian-paste-image\src\paste_image.py`.
; ===================================================================================

; ---- Helper: run a command and return its full stdout+stderr output --------------
RunAndCapture(cmd, workDir := "") {
    tempFile := A_Temp . "\paste_image_" . A_TickCount . ".txt"
    fullCmd  := 'cmd /c ' . cmd . ' > "' . tempFile . '" 2>&1'
    if (workDir != "")
        RunWait(fullCmd, workDir, "Hide")
    else
        RunWait(fullCmd, , "Hide")
    output := ""
    if FileExist(tempFile) {
        output := FileRead(tempFile, "UTF-8")
        FileDelete(tempFile)
    }
    return output
}

; ---- Helper: ask the editor for the current file path via command palette --------
;  Works for VS Code, Antigravity IDE, and any other Electron editor that exposes
;  workbench.action.copyFilePath (Ctrl+Shift+P → "Copy Path").
GetEditorFilePath() {
    try
        activeExe := WinGetProcessName("A")
    catch
        return ""

    knownEditors := ["antigravity.exe", "antigravity ide.exe", "code.exe", "cursor.exe", "windsurf.exe"]
    isEditor := false
    for _, exe in knownEditors {
        if (StrLower(activeExe) = exe) {
            isEditor := true
            break
        }
    }
    if !isEditor
        return ""

    ; Save the full clipboard (images, rich text, etc.)
    savedClip := ClipboardAll()
    A_Clipboard := ""

    ; Open command palette and invoke "Copy Path"
    SendEvent("^+p")
    Sleep(350)
    SendEvent("Copy Path{Enter}")

    gotClip := ClipWait(1.2)

    candidate := ""
    if gotClip {
        candidate := Trim(A_Clipboard)
        ; Validate: must be an absolute Windows path (any extension — Python decides
        ; whether it is inside the vault or not)
        if !RegExMatch(candidate, "^[A-Za-z]:\\.+\\.[a-zA-Z0-9]+$")
            candidate := ""
    }

    ; Restore whatever was in the clipboard before
    A_Clipboard := savedClip
    return candidate
}

UseEditorCopyPathProbe() {
    configPath := "U:\voothi\20260529201233-obsidian-paste-image\config.ini"
    try {
        val := IniRead(configPath, "Obsidian", "editor_copy_path_probe", "false")
    } catch {
        return false
    }

    normalized := StrLower(Trim(val))
    return normalized = "1" || normalized = "true" || normalized = "yes" || normalized = "on"
}

; ==================================================================================

^!i::
{
    activeTitle := WinGetTitle("A")

    ; ---- 1. Passive: parse a full absolute path from the window title ------------
    activeFile := ""
    if RegExMatch(activeTitle, "([A-Za-z]:\\[^\x00-\x1F`\"*<>?|]+\.md)", &mFile) {
        if FileExist(mFile[1])
            activeFile := mFile[1]
    }

    ; ---- 2. Optional active probe: ask the editor directly ------------------------
    if (activeFile = "" && UseEditorCopyPathProbe()) {
        activeFile := GetEditorFilePath()
    }

    ; ---- 3. Extract ZID-prefixed workspace token from the title -----------------
    workspace := ""
    startPos := 1
    while (pos := RegExMatch(activeTitle, "\d{14}-[\w-]+", &mWs, startPos)) {
        workspace := mWs[0]
        startPos := pos + StrLen(mWs[0])
    }

    ; ---- Build command -----------------------------------------------------------
    cmd := "C:\Python\Python312\python.exe U:\voothi\20260529201233-obsidian-paste-image\src\paste_image.py"

    if (activeFile != "")
        cmd .= " --active-file `"" . activeFile . "`""

    if (activeTitle != "")
        cmd .= " --title `"" . activeTitle . "`""

    if (workspace != "")
        cmd .= " --workspace `"" . workspace . "`""

    ; Run and capture all output (no console window shown)
    output := RunAndCapture(cmd, "U:\voothi\20260529201233-obsidian-paste-image")

    ; ---- Show ToolTip with result ------------------------------------------------
    if InStr(output, "[+] Saved:") {
        ; Extract the saved path from the output line  "[+] Saved: <path>"
        savedPath := ""
        for line in StrSplit(output, "`n") {
            if InStr(line, "[+] Saved:") {
                savedPath := Trim(RegExReplace(line, "^\[\+\] Saved:\s*", ""))
                break
            }
        }
        tipText := savedPath != "" ? "✓ " . savedPath : "✓ Image saved to vault"
    } else {
        ; Extract the first error line for display
        errLine := ""
        for line in StrSplit(output, "`n") {
            trimmed := Trim(line)
            if (SubStr(trimmed, 1, 3) = "[!]") {
                errLine := trimmed
                break
            }
        }
        tipText := "✗ " . (errLine != "" ? errLine : "paste_image.py failed — check log")
    }

    ; Read tooltip setting from config.ini
    configPath := "U:\voothi\20260529201233-obsidian-paste-image\config.ini"
    tooltipDuration := 4000 ; default to 4 seconds
    try {
        tooltipVal := IniRead(configPath, "Obsidian", "tooltip", "4000")
        if (tooltipVal = "" || tooltipVal = "0" || tooltipVal = "false" || tooltipVal = "no" || tooltipVal = "off") {
            tooltipDuration := 0
        } else if (tooltipVal = "1" || tooltipVal = "true" || tooltipVal = "yes" || tooltipVal = "on") {
            tooltipDuration := 4000 ; treat as enabled with default duration
        } else {
            tooltipDuration := Integer(tooltipVal)
        }
    }

    if (tooltipDuration > 0) {
        ToolTip(tipText)
        SetTimer(() => ToolTip(), -tooltipDuration)
    }

    ; Pause for system-specific clipboard update delay
    Sleep(300)

    ; CRITICAL Safeguard (Modifier Bleed Prevention):
    ; Wait for the user to physically release Alt and Control
    KeyWait "Alt"
    KeyWait "Control"

    ; Paste the formatted wikilink back, replacing the selection.
    Send("^v")
}
