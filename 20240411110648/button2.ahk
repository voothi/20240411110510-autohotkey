; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Delay in ms before scrolling starts if the cursor is held still.
scrollDelay := 500

; Deadzone for scrolling in pixels. Movement less than this will trigger scroll.
dragThreshold := 15


; ====================================================================================
; --- Script Logic ---
; ====================================================================================

; --- Global variables for Button 1 (Left-Click / Scroll Down) ---
global isScrolling_Btn1 := false
global startX_Btn1 := 0, startY_Btn1 := 0

; --- Global variables for Button 2 (Right-Click / Scroll Up) ---
global isScrolling_Btn2 := false
global startX_Btn2 := 0, startY_Btn2 := 0

; --- Functions for Button 1 ---
GetScrollCount_Down() {
    if WinActive("ahk_exe chrome.exe") { return 3 }
    return 1
}
ScrollDownTimer() {
    loop GetScrollCount_Down() { Send("{WheelDown}") Sleep(50) }
}
CheckForScroll_Btn1() {
    global isScrolling_Btn1, startX_Btn1, startY_Btn1, dragThreshold
    MouseGetPos(&endX, &endY)
    if (Abs(startX_Btn1 - endX) < dragThreshold) && (Abs(startY_Btn1 - endY) < dragThreshold) {
        isScrolling_Btn1 := true
        Send("{LButton Up}")
        SetTimer(ScrollDownTimer, 50)
    }
}

; --- Functions for Button 2 ---
GetScrollCount_Up() {
    if WinActive("ahk_exe chrome.exe") { return 3 }
    return 1
}
ScrollUpTimer() {
    loop GetScrollCount_Up() { Send("{WheelUp}") Sleep(50) }
}
CheckForScroll_Btn2() {
    global isScrolling_Btn2, startX_Btn2, startY_Btn2, dragThreshold
    MouseGetPos(&endX, &endY)
    if (Abs(startX_Btn2 - endX) < dragThreshold) && (Abs(startY_Btn2 - endY) < dragThreshold) {
        isScrolling_Btn2 := true
        Send("{RButton Up}")
        SetTimer(ScrollUpTimer, 50)
    }
}


; ====================================================================================
; --- Hotkeys ---
; ====================================================================================

; --- Hotkey for Button 1: Ctrl+Alt+' (sc028) -> LButton / WheelDown ---
$^!sc028::
{
    global isScrolling_Btn1, startX_Btn1, startY_Btn1, scrollDelay
    isScrolling_Btn1 := false
    MouseGetPos(&startX_Btn1, &startY_Btn1)
    Send("{LButton Down}")
    SetTimer(CheckForScroll_Btn1, -scrollDelay)
}
$^!sc028 up::
{
    global isScrolling_Btn1
    SetTimer(CheckForScroll_Btn1, 0) 
    if isScrolling_Btn1
    {
        SetTimer(ScrollDownTimer, 0)
    }
    else
    {
        Send("{LButton Up}")
    }
}

; --- Hotkey for Button 2: Ctrl+Alt+[ (sc01A) -> RButton / WheelUp ---
$^!sc01A::
{
    global isScrolling_Btn2, startX_Btn2, startY_Btn2, scrollDelay
    isScrolling_Btn2 := false
    MouseGetPos(&startX_Btn2, &startY_Btn2)
    Send("{RButton Down}")
    SetTimer(CheckForScroll_Btn2, -scrollDelay)
}
$^!sc01A up::
{
    global isScrolling_Btn2
    SetTimer(CheckForScroll_Btn2, 0)
    if isScrolling_Btn2
    {
        SetTimer(ScrollUpTimer, 0)
    }
    else {
        Send("{RButton Up}")
    }
}