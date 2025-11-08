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
; Script:       Switch to Anki Browser and Press Ctrl+K
; Hotkey:       Ctrl + Alt + I
;
; Description:  When the Anki "Preview" window is active, this script:
;               1. Finds and activates the main "Browse" window.
;               2. Waits for the "Browse" window to be fully active.
;               3. Sends the key combination Ctrl+K to it.
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

        ; Wait for the window to become fully active (with a 1-second timeout).
        ; This makes the script more reliable.
        if WinWaitActive(foundBrowserID, , 1)
        {
            ; Once it's active, send the Ctrl+K keystroke.
            SendInput("^k")
        }
    }
    else
    {
        ; If the loop finished and we never found it, show an error.
        MsgBox("Script Error: Failed to find the 'Browse' window after checking all of Anki's open windows.", "Window Not Found", "Icon!")
    }
}

; Reset the context-sensitive hotkey directive.
#HotIf