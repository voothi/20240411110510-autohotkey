; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Delay in ms before scrolling starts if the cursor is held still.
scrollDelay := 250 

; Deadzone for scrolling in pixels. Movement less than this will trigger scroll.
dragThreshold := 15 

; Maximum time between clicks to register a double-click (in ms).
doubleClickSpeed := 400

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
    if (Abs(startX - endX) < dragThreshold) && (Abs(startY - endY) < dragThreshold) {
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
    
    ; Double-click logic
    timeDiff := currentTime - lastClickTimestamp
    if (timeDiff < doubleClickSpeed) && (Abs(currentX - lastClickX) < doubleClickThreshold) && (Abs(currentY - lastClickY) < doubleClickThreshold) {
        SetTimer(CheckForScroll, 0)
        Send("{LButton}")
        ignoreUpEvent := true
        return
    }
    
    ; Single-click / Drag / Scroll logic
    lastClickTimestamp := currentTime
    lastClickX := currentX
    lastClickY := currentY
    
    isScrolling := false
    startX := currentX
    startY := currentY
    
    Send("{LButton Down}")
    SetTimer(CheckForScroll, -scrollDelay)
}

$^!sc028 up::
{
    global isScrolling, ignoreUpEvent
    
    if ignoreUpEvent {
        return
    }
    
    SetTimer(CheckForScroll, 0) 
    
    if isScrolling {
        SetTimer(ScrollDownTimer, 0)
    } else {
        Send("{LButton Up}")
    }
}