#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Kill All ffplay Processes
; Author:       [Your Name/Nickname Here]
; Hotkey:       Ctrl + Alt + Shift + 0 (^!+0)
;
; Description:  This script provides a global hotkey to immediately terminate all
;               running instances of `ffplay.exe`. This is particularly useful
;               for quickly stopping audio or video previews that may be launched
;               by other applications (e.g., dictionary tools, media scripts)
;               and don't have an easily accessible close button.
; ===================================================================================

; Define the global hotkey.
^!+0::
{
    ; Find and terminate all running processes with the name "ffplay.exe".
    ProcessClose("ffplay.exe")
    
    ; --- Optional Confirmation Message ---
    ; Uncomment the following lines to display a temporary tooltip in the
    ; center of the screen confirming that the processes were terminated.
    ; ToolTip("ffplay.exe processes terminated", A_ScreenWidth//2, A_ScreenHeight//2)
    ; Sleep(1000)
    ; ToolTip()
}