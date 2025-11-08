; ^!+]:: {
;     If WinActive("ahk_exe anki.exe") {
;         Click()
;         Sleep(150)
;         Send("^a")
;         Sleep(150)
;         Send("^j")
;         Sleep(600)
;         Click()
;         Sleep(150)
;         Send("^!r")
;     }
; }

#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Switch to Anki Browser Window (Robust Version)
; Hotkey:       Ctrl + Alt + I
;
; Description:  When the Anki "Preview" window is active, this script reliably
;               switches back to the main "Browse" window. It works even if the
;               Browser window is inactive.
; ===================================================================================

; This hotkey is only active when the "Preview" window is in focus.
#HotIf WinActive("Preview ahk_exe anki.exe")

^!i::
{
    ; Temporarily allow the script to see hidden or inactive windows.
    DetectHiddenWindows(true)

    ; Get the Process ID (PID) of the currently active Anki window ("Preview").
    ankiPID := WinGetPID("A")

    ; Now, find the window ID of the "Browse" window that belongs to the SAME process.
    ; This is much more reliable than just searching for the title.
    ; We use "RegEx:^Browse" to match any title that starts with "Browse".
    browserWinID := WinExist("RegEx:^Browse ahk_pid " ankiPID)

    ; Restore the default setting for detecting windows.
    DetectHiddenWindows(false)

    ; Check if we successfully found the Browser window's ID.
    if (browserWinID)
    {
        ; If we found it, activate it using its unique ID.
        WinActivate(browserWinID)
    }
    else
    {
        ; If for some reason it's not found, show a message.
        MsgBox("Error: Could not find the Anki 'Browse' window.", "Script Error", "Icon!")
    }
}

; Reset the context-sensitive directive.
#HotIf