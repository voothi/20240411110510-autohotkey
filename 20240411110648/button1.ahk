; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Delay in ms before scrolling starts if the cursor is held still.
scrollDelay := 500

; Deadzone for scrolling in pixels. Movement less than this will trigger scroll.
dragThreshold := 15

; NEW: Deadzone for a "clean click" in pixels. Prevents accidental drags on sensitive elements.
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
        ; --- MODIFIED LOGIC: Differentiate between a clean click and a drag ---
        MouseGetPos(&endX, &endY)
        
        ; Check if the cursor moved less than the click threshold
        if (Abs(startX - endX) < clickThreshold) && (Abs(startY - endY) < clickThreshold)
        {
            ; This is a "clean click".
            ; First, release the LButton to end the current drag state.
            Send("{LButton Up}")
            ; Then, perform a new, precise click at the original start point to ensure accuracy.
            Click(startX, startY)
        }
        else
        {
            ; This is an intentional drag. Just release the button to complete it.
            Send("{LButton Up}")
        }
    }
}