#Requires AutoHotkey v2.0

; ===================================================================================
; CONFIGURATION PARAMETERS
; ===================================================================================
; Time in milliseconds to wait for a second press of the 'X' key.
Global G_MultiTapTimeout := 300 

; Full path to the Python executable.
Global G_PythonPath := "C:\Python\Python312\python.exe"

; Full path to the removal utility script.
Global G_ScriptPath := "U:\voothi\20240310195111-remove-newline-util\remove_newline_util.py"
; ===================================================================================

; Internal state to track the number of presses.
Global G_PressCount := 0

^!X::
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
        ; SINGLE PRESS: Use the current clipboard (Paste Existing).
        ; This handles the case where you copied text elsewhere and just want to paste it cleaned.
        ExecuteUtility(false)
    }
    else
    {
        ; DOUBLE PRESS: Copy selection first, then process and paste.
        ; This handles the case where you have text selected in the current window.
        ExecuteUtility(true)
    }
}

ExecuteUtility(ShouldCopySelection)
{
    if (ShouldCopySelection)
    {
        ; Save the original clipboard just in case the copy fails.
        OriginalClip := A_Clipboard
        A_Clipboard := ""
        Send("^c")
        
        ; Wait up to 500ms for the copy to complete.
        if !ClipWait(0.5, 0)
        {
            ; If copy failed, restore original and continue (or you could return).
            A_Clipboard := OriginalClip
        }
    }
    
    ; If the clipboard is empty, there is nothing to process.
    if (A_Clipboard == "")
    {
        return
    }

    ; Execute the Python script to process the clipboard content.
    RunWait(G_PythonPath . " " . G_ScriptPath, "", "Hide")
    
    ; A short pause to ensure the clipboard is ready for pasting.
    Sleep(500)

    ; Paste the result.
    Send("^v")
}