#Requires AutoHotkey v2.0
#Include Lib\ClipboardUtil.ahk

; ===================================================================================
; Script:       Convert Selected Text to Uppercase
; Hotkey:       Ctrl + Alt + U (^!U)
;
; Description:  This script takes the currently selected text, converts it to 
;               uppercase natively in AHK for speed, and then pastes the result 
;               back, replacing the selection.
; ===================================================================================

^!U:: ; See: CRITICAL Safeguard below
{
    ; Use SmartCopy for reliable selection capture (ZID: 20260505122804)
    if !SmartCopy(0.5)
        return

    ; Process the text natively in AHK for maximum speed
    A_Clipboard := ConvertClipboardCase("upper")
    
    ; CRITICAL Safeguard (ZID: 20260515102336):
    ; Wait for the user to physically release Alt and Control. This prevents the
    ; target application from seeing "Ctrl+Alt+V" instead of "Ctrl+V" (Modifier Bleed).
    KeyWait "Alt"
    KeyWait "Control"

    ; Paste the result immediately
    Send("^v")
}