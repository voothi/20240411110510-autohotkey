#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Focus on Left App/Monitor
; Author:       [Your Name/Nickname Here]
; Hotkey:       Ctrl + Alt + G (^!g)
;
; Description:  This script moves the mouse cursor a fixed distance to the left.
;               It is designed for multi-monitor setups to quickly jump the cursor
;               to an application on a monitor to the left, potentially activating
;               it if "focus follows mouse" is enabled.
;
; IMPORTANT:    The pixel value '-1417' is hardcoded for a specific monitor
;               setup. You will likely need to adjust this value to match the
;               width of your own primary monitor.
; ===================================================================================

^!g::
{
    ; The following commented-out block shows how this hotkey could be made
    ; context-sensitive (e.g., only working when GoldenDict is active).
    ; It is currently disabled, making the hotkey global.
    ; If WinActive("ahk_exe goldendict.exe") {

        ; A delay that was previously used, now disabled.
        ; Sleep(500)

        ; Step 1: Get the current mouse coordinates.
        MouseGetPos(&xpos, &ypos)

        ; Step 2: Instantly move the mouse cursor to the left by 1417 pixels.
        ; The '0' sets the movement speed to be instant.
        ; ADJUST THIS VALUE to fit your screen resolution and layout.
        MouseMove(xpos - 1417, ypos, 0)

        ; The line below could be used to return the cursor to its original position
        ; after the jump. It is currently disabled.
        ; MouseMove(xpos, ypos, 0)
        
    ; } ; End of the disabled context-sensitive block.
}