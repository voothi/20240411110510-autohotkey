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

; The "$" prefix installs a keyboard hook, which prevents the hotkey from triggering itself
; and ensures it blocks the native function of the key combination.
$^!sc01A::
{
    global isScrolling, scrollDelay
    
    isScrolling := false
    SetTimer(LongPressAction, -scrollDelay)
}

$^!sc01A up::
{
    global isScrolling
    
    SetTimer(LongPressAction, 0)
    SetTimer(ScrollUpTimer, 0)
    
    if !isScrolling
    {
        Click("Right")
    }
}