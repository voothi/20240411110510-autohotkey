; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Delay in ms before scrolling starts if the cursor is held still.
scrollDelay := 500

; Deadzone for scrolling in pixels. Movement less than this will trigger scroll.
dragThreshold := 15

; Deadzone for a "clean click" in pixels. Prevents accidental drags.
clickThreshold := 10

; Maximum time between clicks to register a double-click (in ms).
doubleClickSpeed := 500

; Deadzone for double-clicking in pixels.
doubleClickThreshold := 10


; ====================================================================================
; --- Script Logic ---
; ====================================================================================
global isScrolling := false
global startX := 0, startY := 0
global lastClickTimestamp := 0, lastClickX := 0, lastClickY := 0
global ignoreUpEvent := false

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
    global isScrolling, startX, startY, scrollDelay, lastClickTimestamp, lastClickX, lastClickY
    global doubleClickSpeed, doubleClickThreshold, ignoreUpEvent
    
    ignoreUpEvent := false
    currentTime := A_TickCount
    MouseGetPos(&currentX, &currentY)
    
    ; --- Double-click Logic ---
    timeDiff := currentTime - lastClickTimestamp
    if (timeDiff < doubleClickSpeed) && (Abs(currentX - lastClickX) < doubleClickThreshold) && (Abs(currentY - lastClickY) < doubleClickThreshold) {
        SetTimer(CheckForScroll, 0)
        Click() ; Send the second click to complete the double-click
        ignoreUpEvent := true
        lastClickTimestamp := 0 ; Reset to prevent triple-clicks
        return
    }
    
    ; --- Standard Click/Drag/Scroll Logic ---
    isScrolling := false
    startX := currentX
    startY := currentY
    
    Send("{LButton Down}")
    SetTimer(CheckForScroll, -scrollDelay)
}

$^!sc028 up::
{
    global isScrolling, startX, startY, clickThreshold, lastClickTimestamp, lastClickX, lastClickY, ignoreUpEvent
    
    if ignoreUpEvent
    { 
        return 
    }
    
    SetTimer(CheckForScroll, 0) 
    
    if isScrolling
    {
        SetTimer(ScrollDownTimer, 0)
        lastClickTimestamp := 0 ; A scroll action cannot be the first part of a double-click
    }
    else
    {
        MouseGetPos(&endX, &endY)
        
        if (Abs(startX - endX) < clickThreshold) && (Abs(startY - endY) < clickThreshold)
        {
            ; This is a clean single click.
            Send("{LButton Up}")
            Click(startX, startY)
            ; Record its time and position as a potential first click of a double-click.
            lastClickTimestamp := A_TickCount
            lastClickX := startX
            lastClickY := startY
        }
        else
        {
            ; This was a drag.
            Send("{LButton Up}")
            lastClickTimestamp := 0 ; A drag cannot be the first part of a double-click.
        }
    }
}