; #Persistent  ; This line can be omitted in v2 if no persistent state is needed

; Create a function to determine the number of lines to scroll based on the active window
GetScrollCount() {
    if WinActive("ahk_exe app.exe") {  ; Check if app.exe is active
        return 1  ; Number of lines to scroll down for app.exe
    }
    else if WinActive("ahk_exe chrome.exe") {  ; Check if chrome.exe is active
        return 3  ; Number of lines to scroll down for chrome.exe
    }
    else {  ; If none of the specified windows are active
        return 1  ; Default scroll down by one line
    }
}

^!':: {  ; Bind to the hotkey Ctrl + Alt + '
    SetTimer(ScrollDownTimer, 50)
    return
}

^!' up:: {  ; When Ctrl + Alt + ' is released
    SetTimer(ScrollDownTimer, 0)  ; Stop the timer
    return
}

ScrollDownTimer() {  ; Function to execute on each timer tick
    ScrollDownCount := GetScrollCount()  ; Get the number of lines to scroll
    Loop(ScrollDownCount) {  ; Scroll the specified number of lines down
        Send("{WheelDown}")  ; Simulate mouse wheel scrolling down
        Sleep(50)  ; Pause a bit between each scroll action
    }
}