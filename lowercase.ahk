#Requires AutoHotkey v2.0
#Include Lib\ClipboardUtil.ahk

; ===================================================================================
; Script:       Convert Selected Text to Lowercase
; Hotkey:       Ctrl + Alt + I (^!I)
; Description:  Converts selected text to lowercase using native AHK for speed.
; ===================================================================================

^!I::
{
    ; Use SmartCopy for reliable selection capture (ZID: 20260505122804)
    if !SmartCopy(0.5)
        return

    ; Process the text natively in AHK for maximum speed
    A_Clipboard := ConvertClipboardCase("lower")
    
    ; Paste result safely
    SmartPaste()
}