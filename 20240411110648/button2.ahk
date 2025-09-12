; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Delay in ms to hold the key before scrolling starts.
scrollDelay := 250 


; ====================================================================================
; --- Script Logic ---
; ====================================================================================

; Determines the number of lines to scroll up.
GetScrollCount() {
    if WinActive("ahk_exe chrome.exe") {
        return 3
    }
    return 1
}

; Performs the continuous scroll-up action.
ScrollUpTimer() {
    loop GetScrollCount() {
        Send("{WheelUp}")
        Sleep(50)
    }
}

; --- Hotkey ---

; Using a single, self-contained hotkey to prevent race conditions.
$^!sc01A::
{
    ; KeyWait expects the timeout in seconds (T0.25 = 250ms).
    timedOut := KeyWait("sc01A", "T" . (scrollDelay / 1000))

    ; If the key was released BEFORE the timeout (short press).
    if !timedOut
    {
        Click("Right")
        return
    }
    ; If the timeout was reached (long press).
    else
    {
        SetTimer(ScrollUpTimer, 50)
        
        ; Wait indefinitely for the key to be released.
        KeyWait("sc01A")
        
        ; Stop scrolling once the key is up.
        SetTimer(ScrollUpTimer, 0)
        return
    }
}