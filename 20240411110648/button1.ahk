; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Delay in ms to hold the key before scrolling starts.
scrollDelay := 250 


; ====================================================================================
; --- Script Logic ---
; ====================================================================================
global isScrolling := false

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

; This function is triggered by a timer and starts the scroll.
LongPressAction() {
    global isScrolling
    isScrolling := true
    SetTimer(ScrollUpTimer, 50)
}


; --- Hotkeys ---

; Triggers on KEY DOWN for the physical key `[` (sc01A).
$^!sc01A::
{
    global isScrolling, scrollDelay
    
    isScrolling := false ; Reset the flag on each new press.
    SetTimer(LongPressAction, -scrollDelay) ; Start a one-time timer that will trigger the scroll.
}

; Triggers on KEY UP for the physical key `[` (sc01A).
$^!sc01A up::
{
    global isScrolling
    
    ; Immediately disable all timers.
    SetTimer(LongPressAction, 0)
    SetTimer(ScrollUpTimer, 0)
    
    ; If the scroll timer never had a chance to run, it was a short press.
    if !isScrolling
    {
        Click("Right")
    }
}