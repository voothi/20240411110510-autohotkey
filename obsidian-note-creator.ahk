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
;               A ToolTip confirms the created notes or errors. Auto-dismisses
;               after 4 seconds.
;
; Dependencies:
;   - Python 3 must be installed.
;   - Pyperclip must be installed in Python.
;   - `note_creator.py` at `U:\voothi\20260529182202-obsidian-note-creator\src\note_creator.py`.
; ===================================================================================

; ---- Helper: run a command and return its full stdout+stderr output --------------
RunAndCapture(cmd, workDir := "") {
    tempFile := A_Temp . "\note_creator_" . A_TickCount . ".txt"
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

    ; Run and capture all output (no console window shown)
    output := RunAndCapture(cmd, "U:\voothi\20260529182202-obsidian-note-creator")
    
    ; ---- Show ToolTip with result ------------------------------------------------
    createdNotes := []
    errors := []
    alreadyExistsNotes := []
    noZidFound := false
    
    for line in StrSplit(output, "`n") {
        trimmed := Trim(line)
        if InStr(trimmed, "[+] Created Note:") {
            notePath := Trim(RegExReplace(trimmed, "^\[\+\] Created Note:\s*", ""))
            createdNotes.Push(notePath)
        } else if InStr(trimmed, "[Error]") {
            errors.Push(Trim(RegExReplace(trimmed, "^\[Error\]\s*", "")))
        } else if InStr(trimmed, "already exists. Skipping file creation") {
            if RegExMatch(trimmed, "'([^']+)'", &match) {
                alreadyExistsNotes.Push(match[1])
            } else {
                alreadyExistsNotes.Push("Note")
            }
        } else if InStr(trimmed, "No ZID") {
            noZidFound := true
        }
    }
    
    if (errors.Length > 0) {
        tipText := "✗ " . errors[1]
    } else if (createdNotes.Length > 0) {
        if (createdNotes.Length = 1)
            tipText := "✓ Created: " . createdNotes[1]
        else
            tipText := "✓ Created " . createdNotes.Length . " notes"
    } else if (alreadyExistsNotes.Length > 0) {
        if (alreadyExistsNotes.Length = 1)
            tipText := "! Already exists: " . alreadyExistsNotes[1]
        else
            tipText := "! " . alreadyExistsNotes.Length . " notes already exist"
    } else if (noZidFound) {
        tipText := "✗ No ZIDs found in clipboard"
    } else {
        tipText := "✓ Note creator completed"
    }

    ; Read tooltip setting from config.ini
    configPath := "U:\voothi\20260529182202-obsidian-note-creator\config.ini"
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

    ; CRITICAL Safeguard (ZID: 20260515102336):
    ; Wait for the user to physically release Alt and Control to prevent Modifier Bleed.
    KeyWait "Alt"
    KeyWait "Control"

    ; Step 3: Paste the formatted wikilinks back, replacing the selection.
    Send("^v")
}
