#Requires AutoHotkey v2.0

; ====================================================================================
; Script:       Advanced Mouse Button Remapper
; Description:  This script overloads a single key/button (identified by its 
;               scan code, sc028) to perform multiple actions:
;               - Single Click: A normal left-click.
;               - Double-Click: A normal left double-click.
;               - Drag: Standard click-and-drag functionality.
;               - Scroll on Hold: If the button is held down without moving the
;                 mouse, it initiates an automatic vertical scroll down.
;
; Note:         The hotkey `sc028` is a scan code. You may need to use AHK's
;               KeyHistory tool to find the correct scan code for your target button
;               (e.g., a side mouse button).
; ====================================================================================


; ====================================================================================
; --- User Configuration ---
; These variables allow you to customize the button's behavior.
; ====================================================================================

; Delay in milliseconds before auto-scrolling starts when the button is held still.
scrollDelay := 500

; The distance (in pixels) the mouse can move while held down before the auto-scroll
; is cancelled. If movement is less than this, scroll will engage.
dragThreshold := 7

; The maximum distance (in pixels) the mouse can move between button press and 
; release to be considered a "clean click" instead of a drag.
clickThreshold := 10

; The maximum time (in milliseconds) allowed between two clicks to register as a 
; double-click.
doubleClickSpeed := 500

; The maximum distance (in pixels) the mouse can move between two clicks for them
; to be registered as a double-click.
doubleClickThreshold := 10


; ====================================================================================
; --- Script Logic (State Management and Timers) ---
; ====================================================================================

; --- Global Variables for State Tracking ---
global isScrolling := false      ; Flag to indicate if the auto-scroll feature is active.
global startX := 0, startY := 0  ; Stores the mouse coordinates when the button is pressed.
global lastClickTimestamp := 0   ; Timestamp of the last valid single click (for double-click detection).
global lastClickX := 0, lastClickY := 0 ; Coordinates of the last click.
global ignoreUpEvent := false    ; Flag to prevent the 'up' hotkey from firing after a double-click.


; --- Helper Functions ---

; Determines how many scroll lines to send per tick.
; Provides faster scrolling in specific applications like Chrome.
GetScrollCount() {
    if WinActive("ahk_exe chrome.exe") {
        return 3 ; Scroll faster in Chrome.
    }
    return 1 ; Default scroll speed for other apps.
}

; This function is called repeatedly by a timer to perform the auto-scroll action.
ScrollDownTimer() {
    loop GetScrollCount() {
        Send("{WheelDown}")
        Sleep(50) ; Small delay between scroll ticks for smoothness.
    }
}

; This function runs once after `scrollDelay` when the button is held down.
; It checks if the mouse has remained stationary to decide if auto-scroll should start.
CheckForScroll() {
    global isScrolling, startX, startY, dragThreshold
    MouseGetPos(&endX, &endY)
    
    ; Check if the cursor is still within the deadzone.
    if (Abs(startX - endX) < dragThreshold) && (Abs(startY - endY) < dragThreshold)
    {
        ; If so, start scrolling.
        isScrolling := true
        Send("{LButton Up}") ; Release the virtual left-click before scrolling.
        SetTimer(ScrollDownTimer, 50) ; Start the repeating scroll timer.
    }
}


; ====================================================================================
; --- Hotkeys ---
; ====================================================================================

; This hotkey triggers when the specified button is PRESSED DOWN.
$^!sc028::
{
    global isScrolling, startX, startY, scrollDelay, lastClickTimestamp, lastClickX, lastClickY
    global doubleClickSpeed, doubleClickThreshold, ignoreUpEvent
    
    ignoreUpEvent := false
    currentTime := A_TickCount
    MouseGetPos(&currentX, &currentY)
    
    ; --- Double-click Detection Logic ---
    timeDiff := currentTime - lastClickTimestamp
    isWithinTime := timeDiff < doubleClickSpeed
    isWithinDistance := (Abs(currentX - lastClickX) < doubleClickThreshold) && (Abs(currentY - lastClickY) < doubleClickThreshold)

    if (isWithinTime && isWithinDistance) {
        SetTimer(CheckForScroll, 0) ; Cancel the pending scroll check.
        Click() ; Send a standard click to complete the double-click action.
        ignoreUpEvent := true ; Tell the 'up' hotkey to do nothing on release.
        lastClickTimestamp := 0 ; Reset timestamp to prevent triple-clicks.
        return
    }
    
    ; --- Standard Click/Drag/Scroll Preparation ---
    isScrolling := false
    startX := currentX
    startY := currentY
    
    Send("{LButton Down}") ; Begin a virtual left mouse button press.
    SetTimer(CheckForScroll, -scrollDelay) ; Start a one-time timer to check for auto-scroll.
}

; This hotkey triggers when the specified button is RELEASED.
$^!sc028 up::
{
    global isScrolling, startX, startY, clickThreshold, lastClickTimestamp, lastClickX, lastClickY, ignoreUpEvent
    
    ; If this is the release after a successful double-click, do nothing.
    if ignoreUpEvent { 
        return 
    }
    
    SetTimer(CheckForScroll, 0) ; Always cancel the scroll check timer on release.
    
    if isScrolling {
        ; If we were auto-scrolling, simply stop the scroll timer.
        SetTimer(ScrollDownTimer, 0)
        lastClickTimestamp := 0 ; A scroll action cannot be the first part of a double-click.
    } else {
        MouseGetPos(&endX, &endY)
        
        isWithinClickThreshold := (Abs(startX - endX) < clickThreshold) && (Abs(startY - endY) < clickThreshold)

        if isWithinClickThreshold {
            ; This was a clean single click (not a drag).
            Send("{LButton Up}")
            ; Send a click at the original position for reliability, though LButton Up is often enough.
            Click(startX, startY) 
            
            ; Record its time and position as a potential first click of a future double-click.
            lastClickTimestamp := A_TickCount
            lastClickX := startX
            lastClickY := startY
        } else {
            ; This was a drag action.
            Send("{LButton Up}") ; Simply release the mouse button to end the drag.
            lastClickTimestamp := 0 ; A drag cannot be the first part of a double-click.
        }
    }
}