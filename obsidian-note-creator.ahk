#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Obsidian ZID Note Creator Hotkey
; Hotkey:       Ctrl + Alt + K (^!k)
;
; Description:  Copies selected text (which starts with or contains ZID lines),
;               calls note_creator.py to batch create notes exactly 1-to-1,
;               updates the active conversation log MOC, copies the formatted
;               Obsidian wikilinks back to the clipboard, and optionally pastes them.
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

ShouldAutoPasteWikilinks() {
    configPath := "U:\voothi\20260529182202-obsidian-note-creator\config.ini"
    try {
        val := IniRead(configPath, "Obsidian", "auto_paste_wikilinks", "false")
    } catch {
        return false
    }

    normalized := StrLower(Trim(val))
    return normalized = "1" || normalized = "true" || normalized = "yes" || normalized = "on"
}

^!z::
{
    ; Extract the active window title to parse the workspace (e.g., 20260308110646-kardenwort-mpv)
    activeTitle := WinGetTitle("A")
    workspace := ""
    startPos := 1
    while (pos := RegExMatch(activeTitle, "\d{14}-[\w-]+", &match, startPos)) {
        ; VSCode window titles can include both the file slug and workspace slug.
        ; Keep the rightmost match, which is typically the workspace token.
        workspace := match[0]
        startPos := pos + StrLen(match[0])
    }

    ; Step 1: Copy the selected text to system clipboard.
    ; Preserve existing clipboard if nothing is selected (preventing empty overwrite)
    savedClip := ClipboardAll()
    A_Clipboard := ""
    
    Send("^c")
    if !ClipWait(0.3) ; Wait briefly for copy
    {
        ; No selection: restore previously copied content
        A_Clipboard := savedClip
    } else {
        ; Check if copied text is empty or just whitespace/newlines
        if (Trim(A_Clipboard, " `t`r`n") = "") {
            A_Clipboard := savedClip
        }
    }

    if (A_Clipboard = "")
    {
        MsgBox("Clipboard is empty and nothing is selected.", "Error", 16)
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
    resolvedExistingNotes := []
    mocUpdated := false
    mocSkipped := false
    noZidFound := false
    
    for line in StrSplit(output, "`n") {
        trimmed := Trim(line)
        if InStr(trimmed, "[+] Created Note:") {
            notePath := Trim(RegExReplace(trimmed, "^\[\+\] Created Note:\s*", ""))
            createdNotes.Push(notePath)
        } else if InStr(trimmed, "[Error]") {
            errors.Push(Trim(RegExReplace(trimmed, "^\[Error\]\s*", "")))
        } else if InStr(trimmed, "[!] Clipboard is empty.") {
            errors.Push("Clipboard is empty.")
        } else if InStr(trimmed, "Traceback (most recent call last):") {
            errors.Push("Python traceback detected. See note creator output.")
        } else if RegExMatch(trimmed, "^(FileNotFoundError|PermissionError|ModuleNotFoundError|RuntimeError|Exception):") {
            errors.Push(trimmed)
        } else if InStr(trimmed, "already exists. Skipping file creation") {
            if RegExMatch(trimmed, "'([^']+)'", &match) {
                alreadyExistsNotes.Push(match[1])
            } else {
                alreadyExistsNotes.Push("Note")
            }
        } else if InStr(trimmed, "Found existing note for ZID") {
            if RegExMatch(trimmed, "ZID \d+: ([^\s]+)", &match) {
                resolvedExistingNotes.Push(match[1])
            } else {
                resolvedExistingNotes.Push("Note")
            }
        } else if InStr(trimmed, "Successfully updated MOC") {
            mocUpdated := true
        } else if InStr(trimmed, "already exists in conversation MOC") {
            mocSkipped := true
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
    } else if (alreadyExistsNotes.Length > 0 || resolvedExistingNotes.Length > 0) {
        existingName := resolvedExistingNotes.Length > 0 ? resolvedExistingNotes[1] : alreadyExistsNotes[1]
        ; Strip paths to keep filenames short and legible in the tooltip
        if RegExMatch(existingName, "[^\\]+$", &mName) {
            existingName := mName[0]
        }
        
        if (mocUpdated) {
            tipText := "✓ Linked existing: " . existingName
        } else {
            tipText := "! Already linked: " . existingName
        }
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

    if ShouldAutoPasteWikilinks() {
        ; Step 3: Paste the formatted wikilinks back, replacing the selection.
        Send("^v")
    }
}
