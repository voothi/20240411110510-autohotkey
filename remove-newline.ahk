#Requires AutoHotkey v2.0

; ===================================================================================
; CONFIGURATION PARAMETERS
; ===================================================================================
; Time in milliseconds to wait for a second press of the 'X' key.
Global G_MultiTapTimeout := 300 

#Include Lib\ClipboardUtil.ahk

; Internal state to track the number of presses.
Global G_PressCount := 0

^!X:: ; See: CRITICAL Safeguard (ExecuteUtility)
{
    Global G_PressCount
    G_PressCount += 1
    
    ; Start the timer on the first press.
    if (G_PressCount == 1)
    {
        ; The minus sign in -300 means "run once after 300ms".
        SetTimer(HandleSmartAction, -G_MultiTapTimeout)
    }
}

HandleSmartAction()
{
    Global G_PressCount
    Taps := G_PressCount
    G_PressCount := 0 ; Reset for next time.
    
    if (Taps == 1)
    {
        ; SINGLE PRESS: Copy selection first, then process and paste.
        ; (Backward compatibility with the original selection-based behavior)
        ExecuteUtility(true)
    }
    else
    {
        ; DOUBLE PRESS: Use the current clipboard (Paste Existing).
        ; (Special mode to clean whatever you already copied elsewhere)
        ExecuteUtility(false)
    }
}

ExecuteUtility(ShouldCopySelection)
{
    if (ShouldCopySelection)
    {
        ; Use SmartCopy for reliable selection capture (ZID: 20260505122804)
        if !SmartCopy(0.5)
            return
    }
    
    ; If the clipboard is empty, there is nothing to process.
    if (A_Clipboard == "")
    {
        return
    }

    ; NATIVE SPEEDUP: Process the text in AHK instead of calling external Python.
    A_Clipboard := CleanClipboardText(A_Clipboard)
    
    ; CRITICAL Safeguard (ZID: 20260515102336):
    ; Wait for the user to physically release Alt and Control. This prevents the
    ; target application from seeing "Ctrl+Alt+V" instead of "Ctrl+V" (Modifier Bleed),
    ; which is the most common cause of paste failure in these utilities.
    KeyWait "Alt"
    KeyWait "Control"

    ; Paste the result.
    Send("^v")
}