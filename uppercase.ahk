#Requires AutoHotkey v2.0
#Include Lib\ClipboardUtil.ahk

; ===================================================================================
; Script:       Convert Selected Text to Uppercase
; Hotkey:       Ctrl + Alt + U (^!U)
; Description:  Converts selected text to uppercase using native AHK for speed.
; ===================================================================================

^!U::
{
    ; Use SmartCopy for reliable selection capture (ZID: 20260505122804)
    if !SmartCopy(0.5)
        return

    ; Process the text natively in AHK for maximum speed
    A_Clipboard := ConvertClipboardCase("upper")
    
    ; Paste the result immediately
    Send("^v")
}