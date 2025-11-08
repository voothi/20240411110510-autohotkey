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
; Script:       Anki Browser Round-Trip Action
; Hotkey:       Ctrl + Alt + I
;
; Description:  When the Anki "Preview" window is active, this script:
;               1. Finds and activates the main "Browse" window.
;               2. Sends the key combination Ctrl+K.
;               3. Returns focus back to the original "Preview" window.
; ===================================================================================

; Hotkey is only active when the "Preview" window is in focus.
#HotIf WinActive("Preview ahk_exe anki.exe")

^!i::
{
    ; Step 1: Save the unique ID of the starting "Preview" window.
    previewWinID := WinGetID("A")

    ; --- Find the "Browse" window ---
    allAnkiWindows := WinGetList("ahk_exe anki.exe")
    foundBrowserID := 0
    for id in allAnkiWindows
    {
        currentTitle := WinGetTitle(id)
        if RegExMatch(currentTitle, "^Browse")
        {
            foundBrowserID := id
            break
        }
    }

    ; --- Perform actions if the "Browse" window was found ---
    if (foundBrowserID)
    {
        ; Step 2: Activate the "Browse" window.
        WinActivate(foundBrowserID)

        ; Wait for it to become fully active.
        if WinWaitActive(foundBrowserID, , 1)
        {
            ; Step 3: Send the Ctrl+K keystroke.
            SendInput("^k")

            ; Step 4: Add a brief pause to ensure the command is processed.
            Sleep(200)

            ; Step 5: Activate the original "Preview" window again.
            WinActivate(previewWinID)
        }
    }
    else
    {
        ; If the "Browse" window was not found, show an error.
        MsgBox("Script Error: Failed to find the 'Browse' window.", "Window Not Found", "Icon!")
    }
}

; Reset the context-sensitive hotkey directive.
#HotIf