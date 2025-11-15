#Requires AutoHotkey v2.0

; ====================================================================================
; Script:       Short-Press vs. Long-Press Button
; Description:  This script remaps a single key/button (identified by its scan 
;               code, sc01A) to perform two different actions:
;               - Short Press (Tap): Executes a right mouse click.
;               - Long Press (Hold): Initiates a continuous scroll up.
;
; Note:         The hotkey `sc01A` is a scan code. You may need to use AHK's
;               KeyHistory tool to find the correct scan code for your target button.
; ====================================================================================


; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; The time (in milliseconds) the button must be held down to trigger the 
; long-press action (scrolling) instead of the short-press action (right-click).
scrollDelay := 250


; ====================================================================================
; --- Script Logic (State Management and Timers) ---
; ====================================================================================

; A global flag to track whether the long-press action (scrolling) has been triggered.
global isScrolling := false


; --- Helper Functions ---

; Determines how many scroll lines to send per tick.
; Provides faster scrolling in specific applications like Chrome.
GetScrollCount() {
    if WinActive("ahk_exe chrome.exe") {
        return 3 ; Scroll faster in Chrome.
    }
    return 1 ; Default scroll speed for other apps.
}

; This function is called repeatedly by a timer to perform the scroll-up action.
ScrollUpTimer() {
    loop GetScrollCount() {
        Send("{WheelUp}")
        Sleep(50) ; Small delay between scroll ticks for smoothness.
    }
}

; This function is the callback for a successful long press. It runs once after 
; `scrollDelay` has passed, sets the scrolling state, and starts the repeating scroll timer.
LongPressAction() {
    global isScrolling
    isScrolling := true
    SetTimer(ScrollUpTimer, 50)
}


; ====================================================================================
; --- Hotkeys ---
; ====================================================================================

; This hotkey triggers when the specified button is PRESSED DOWN.
; The "$" prefix installs a keyboard hook, which prevents the hotkey from triggering 
; itself and ensures it blocks the native function of the key.
$^!sc01A::
{
    global isScrolling, scrollDelay
    
    ; Reset the state at the beginning of every press.
    isScrolling := false
    
    ; Start a one-time timer. If this timer completes before the button is released,
    ; the `LongPressAction` will be executed.
    SetTimer(LongPressAction, -scrollDelay)
}

; This hotkey triggers when the specified button is RELEASED.
$^!sc01A up::
{
    global isScrolling
    
    ; Immediately cancel both timers. This stops the long-press from triggering if
    ; the button is released, and it stops the scrolling if it was already active.
    SetTimer(LongPressAction, 0)
    SetTimer(ScrollUpTimer, 0)
    
    ; Check the state to determine if this was a short press or a long press.
    if !isScrolling
    {
        ; If `isScrolling` is still false, it means `LongPressAction` never ran.
        ; This was a short press (a tap), so we execute the right-click.
        Click("Right")
    }
    ; If `isScrolling` was true, we don't need to do anything else, because the
    ; timers have already been stopped. The release simply ends the long-press action.
}