#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Anki UI Refresh Trigger
; Author:       [Your Name/Nickname Here]
; Hotkey:       Ctrl + Alt + R (^!r)
;
; Description:  This script is designed to run within Anki. It sends a key 
;               combination and then performs a quick mouse movement. This is 
;               often used as a workaround to force a UI refresh or trigger an 
;               action that might not respond to keystrokes alone (e.g.,
;               updating a button's state or an add-on's panel).
; ===================================================================================

^!r::
{
    ; Only run if an Anki window is active.
    if WinActive("ahk_exe anki.exe")
    {
        ; Wait a moment to ensure Anki is ready to receive input.
        Sleep(500)

        ; Send the Ctrl+Shift+P key combination.
        ; Note: The commented line below might be an alternative or previous method.
        ; Send("^!{p}")
        Send("^+p")

        ; Pause again to allow the previous command to be processed.
        Sleep(500)

        ; The following mouse movements are a technique to force a UI update.
        ; It quickly moves the cursor and returns it, which can trigger hover
        ; events or cause elements to redraw.

        ; Step 1: Get the current mouse coordinates.
        MouseGetPos(&xpos, &ypos)

        ; Step 2: Briefly move the mouse cursor far to the right.
        ; The '0' sets the movement speed to be instant.
        MouseMove(xpos + 1024, ypos, 0)

        ; Step 3: Immediately return the cursor to its original position.
        MouseMove(xpos, ypos, 0)
    }
}