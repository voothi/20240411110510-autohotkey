; #Persistent  ; This line can be omitted in v2 if no persistent state is needed

; Create a function to determine the number of lines to scroll based on the active window
GetScrollCount() {
    if WinActive("ahk_exe app.exe") {  ; Check if app.exe is active
        return 1  ; Number of lines to scroll up for app.exe
    } 
    else if WinActive("ahk_exe chrome.exe") {  ; Check if chrome.exe is active
        return 3  ; Number of lines to scroll up for chrome.exe
    } 
    else {  ; If neither of the specified windows is active
        return 1  ; Default scroll up by three lines
    }
}

^![:: {  ; Bind to the hotkey Ctrl + Shift + [
    ScrollUpCount := GetScrollCount()  ; Get the number of lines to scroll
    Loop(ScrollUpCount) {  ; Scroll the specified number of lines up
        Send("{WheelUp}")  ; Simulate mouse wheel scrolling up
        Sleep(50)  ; Pause a bit between each scroll action
    }
}