; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Delay in ms before scrolling starts if the cursor is held still.
scrollDelay := 500

; Deadzone for scrolling in pixels. Movement less than this will trigger scroll.
dragThreshold := 15

; Deadzone for a "clean click" in pixels. Prevents accidental drags on sensitive elements.
; A small value like 5-10 is recommended.
clickThreshold := 7


; ====================================================================================
; --- Script Logic ---
; ====================================================================================
global isScrolling := false
global startX := 0, startY := 0

GetScrollCount() {
    if WinActive("ahk_exe chrome.exe") {
        return 3
    }
    return 1
}

ScrollDownTimer() {
    loop GetScrollCount() {
        Send("{WheelDown}")
        Sleep(50)
    }
}

CheckForScroll() {
    global isScrolling, startX, startY, dragThreshold
    MouseGetPos(&endX, &endY)
    
    if (Abs(startX - endX) < dragThreshold) && (Abs(startY - endY) < dragThreshold)
    {
        isScrolling := true
        Send("{LButton Up}")
        SetTimer(ScrollDownTimer, 50)
    }
}

; --- Hotkeys ---

$^!sc028::
{
    global isScrolling, startX, startY, scrollDelay
    
    isScrolling := false
    MouseGetPos(&startX, &startY)
    
    Send("{LButton Down}")
    SetTimer(CheckForScroll, -scrollDelay)
}

$^!sc028 up::
{
    global isScrolling, startX, startY, clickThreshold
    
    SetTimer(CheckForScroll, 0) 
    
    if isScrolling
    {
        SetTimer(ScrollDownTimer, 0)
    }
    else
    {
        MouseGetPos(&endX, &endY)
        
        if (Abs(startX - endX) < clickThreshold) && (Abs(startY - endY) < clickThreshold)
        {
            Send("{LButton Up}")
            Click(startX, startY)
        }
        else
        {
            Send("{LButton Up}")
        }
    }
}