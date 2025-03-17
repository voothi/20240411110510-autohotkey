#Requires AutoHotkey v2.0

; Set tray icon and tooltip
TraySetIcon(".\assets\arrow-55-16.ico")  ; Set your custom tray icon
A_IconTip := "Press Pause Script to disable temporarily"  ; Set tooltip for the tray icon

; Your script code goes here...

; Initialize a flag to track if the timer is set
global TimerIsSet := false

; Function to check the conditions and manage the timer
CheckConditions() {
    global TimerIsSet ; Declare TimerIsSet as global to use the global variable

    ; Check if the active window is Chrome and if the title contains "Reading", "Translate", or "Text Input"
    if (
        (
            WinActive("ahk_exe chrome.exe") &&
            (InStr(WinGetTitle("A"), "Reading") ||
            InStr(WinGetTitle("A"), "Translate") ||
            InStr(WinGetTitle("A"), "Text Input"))
        ) ||
        WinActive("ahk_exe goldendict.exe") ||
        WinActive("ahk_exe potplayermini64.exe")
    ) {
        ; If the timer is not already set, set it
        if (!TimerIsSet) {
            SetTimer(SwitchToEnglishLayoutIfNeeded, 10000) ; Set the timer to call the function every 2 minutes
            TimerIsSet := true
        }
    } else {
        ; If the active window does not meet the conditions, stop the timer
        if (TimerIsSet) {
            SetTimer(SwitchToEnglishLayoutIfNeeded, 0) ; Turn off the timer by setting the interval to 0
            TimerIsSet := false
        }
    }
}

; Set a timer to check the conditions every 500 milliseconds
SetTimer(CheckConditions, 1000)

GetKeyboardLayout() {
    ; This function returns the current keyboard layout identifier
    ; We use DllCall to retrieve the layout
    return DllCall("GetKeyboardLayout", "UInt", 0, "UInt")
}

ChangeKeyboardLayout(layout) {
    ; Change the keyboard layout by using the DllCall to LoadKeyboardLayout
    ; DllCall("LoadKeyboardLayout", "Str", layout, "UInt", 1)
    PostMessage(0x50, 0, layout, , "A")  ; 0x50 is WM_INPUTLANGCHANGEREQUEST. Switch the active window's keyboard layout/language to English:
}

SwitchToEnglishLayoutIfNeeded() {
    ; Get the current keyboard layout
    currentLayout := GetKeyboardLayout()

    ; Debugging: Display the current layout handle
    ; Tooltip("Current Layout Handle: " currentLayout)
    ; Sleep(2000) ; Show the tooltip for 2 секунды
    ; Tooltip() ; Clear the tooltip

    ; Define layout identifiers for English (US) and Italian
    englishLayout := 0x0409  ; English (United States)

    ; Display the current layout code for debugging
    ; Tooltip("Current Layout Code: " currentLayout)
    ; Sleep(2000)

    ; Check if the current layout is not English
    if (currentLayout != englishLayout) {
        ; Simulate the layout switch using Shift + Alt
        ChangeKeyboardLayout(englishLayout) ; 67699721 00000409 Load Keyboard Layout for English US (Hex representation)
        Sleep(100) ; Wait a little for the layout to change
        ; Get the new keyboard layout after the change
        newLayout := GetKeyboardLayout()

        ; Display the new layout code for debugging
        ; Tooltip("New Layout Code: " newLayout)
        ; Sleep(2000)
        ; Tooltip() ; Clear the tooltip after 2 seconds
    }
}
