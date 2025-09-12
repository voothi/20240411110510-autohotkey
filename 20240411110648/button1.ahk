; Global flag to differentiate between a short press and a long press.
isShortPress := true

; Determines the number of lines to scroll based on the active window.
GetScrollCount() {
    if WinActive("ahk_exe app.exe") {
        return 1
    }
    else if WinActive("ahk_exe chrome.exe") {
        return 3
    }
    else {
        return 1
    }
}

; Performs the continuous scroll action.
ScrollDownTimer() {
    ScrollDownCount := GetScrollCount()
    loop ScrollDownCount {
        Send("{WheelDown}")
        Sleep(50)
    }
}

; This function is triggered after 500ms, defining the action as a "long press".
LongPressAction() {
    isShortPress := false
    SetTimer(ScrollDownTimer, 50) ; Starts the continuous scroll.
}

; --- Hotkeys ---

; Triggers on KEY DOWN for the physical key sc028 (' key in US layout).
^!sc028::
{
    isShortPress := true ; Assume a short press until the timer completes.
    SetTimer(LongPressAction, -500) ; Start a one-time timer for 500ms.
}

; Triggers on KEY UP for the physical key sc028.
^!sc028 up::
{
    ; Immediately disable all related timers.
    SetTimer(LongPressAction, 0)
    SetTimer(ScrollDownTimer, 0)

    ; If the timer didn't have time to run, it was a short press.
    if isShortPress
    {
        Click()
    }
}