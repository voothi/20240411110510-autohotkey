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
; Script:       Switch to Anki Browser Window (Final, Robust Version)
; Hotkey:       Ctrl + Alt + I
;
; Description:  When the Anki "Preview" window is active, this script finds and
;               activates the main "Browse" window. This version manually iterates
;               through all of Anki's open windows to ensure the target is found,
;               even if it's inactive or hidden by the UI framework.
; ===================================================================================

; Hotkey is only active when the "Preview" window is in focus.
#HotIf WinActive("Preview ahk_exe anki.exe")

^!i::
{
    ; Get a list of all unique window IDs (hWnds) for the anki.exe process.
    allAnkiWindows := WinGetList("ahk_exe anki.exe")
    
    ; Variable to store the ID of the browse window if we find it.
    foundBrowserID := 0

    ; Loop through each window ID that belongs to Anki.
    for id in allAnkiWindows
    {
        ; Get the title of the current window in the loop.
        currentTitle := WinGetTitle(id)
        
        ; Check if the title starts with "Browse". 
        ; RegExMatch is a reliable way to do this.
        if RegExMatch(currentTitle, "^Browse")
        {
            ; We found it! Store the unique ID and stop the loop.
            foundBrowserID := id
            break
        }
    }

    ; After checking all windows, see if we found the Browser.
    if (foundBrowserID)
    {
        ; If we have a valid ID, activate the window.
        WinActivate(foundBrowserID)
    }
    else
    {
        ; If the loop finished and we never found it, show an error.
        MsgBox("Script Error: Failed to find the 'Browse' window after checking all of Anki's open windows.", "Window Not Found", "Icon!")
    }
}

; Reset the context-sensitive hotkey directive.
#HotIf