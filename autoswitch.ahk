#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Auto Language Switcher
; Description:  This script automatically switches the keyboard layout to English
;               when specific applications or browser tabs are active. This is
;               useful for tools like dictionaries, translation websites, or media
;               players where English input is typically preferred.
; ===================================================================================

; --- Tray Menu Configuration ---
TraySetIcon(".\assets\arrow-55-16.ico")  ; Set a custom tray icon. Assumes the icon is in an 'assets' subfolder.
A_IconTip := "Auto Language Switcher is active. Pause script to disable." ; Set tooltip for the tray icon.

; --- Global Variables ---
; A global flag to track whether the layout-switching timer is currently active.
global TimerIsSet := false

; This is the main loop driver. It runs the CheckConditions function every second
; to determine if the layout-switching logic should be active.
SetTimer(CheckConditions, 1000)

; ===================================================================================
;                                   MAIN LOGIC
; ===================================================================================

; Checks the active window and decides whether to start or stop the layout-switching timer.
CheckConditions() {
    global TimerIsSet ; Use the global flag.

    ; Define the conditions for activation.
    isChromeActive := WinActive("ahk_exe chrome.exe")
    isGoldenDictActive := WinActive("ahk_exe goldendict.exe")
    isPotPlayerActive := WinActive("ahk_exe potplayermini64.exe")
    
    ; For Chrome, check if the title contains keywords related to translation or reading.
    chromeTitle := isChromeActive ? WinGetTitle("A") : ""
    isChromeTitleMatch := isChromeActive && (InStr(chromeTitle, "Reading") || InStr(chromeTitle, "Translate") || InStr(chromeTitle, "Text Input"))

    if (isChromeTitleMatch || isGoldenDictActive || isPotPlayerActive) {
        ; If conditions are met and the timer isn't already running, start it.
        if (!TimerIsSet) {
            ; This timer calls the switching function every 10 seconds (10000 ms).
            SetTimer(SwitchToEnglishLayoutIfNeeded, 10000) 
            TimerIsSet := true
        }
    } else {
        ; If the active window no longer meets the conditions, stop the timer to save resources.
        if (TimerIsSet) {
            SetTimer(SwitchToEnglishLayoutIfNeeded, 0) ; A value of 0 turns off the timer.
            TimerIsSet := false
        }
    }
}

; This function is called by the timer. It checks the current layout and switches to English if necessary.
SwitchToEnglishLayoutIfNeeded() {
    currentLayout := GetKeyboardLayout()
    englishLayout := 0x0409  ; Language identifier for English (United States).

    ; --- For debugging: uncomment these lines to see the layout codes in a tooltip ---
    ; Tooltip("Current Layout Handle: " currentLayout)
    ; Sleep(2000) ; Show the tooltip for 2 seconds.
    ; Tooltip()   ; Clear the tooltip.

    ; If the current layout is not English, perform the switch.
    if (currentLayout != englishLayout) {
        ChangeKeyboardLayout(englishLayout)
        Sleep(100) ; A brief pause to allow the system to process the layout change.
        
        ; --- For debugging: check the layout code after the switch attempt ---
        ; newLayout := GetKeyboardLayout()
        ; Tooltip("New Layout Code: " newLayout)
        ; Sleep(2000)
        ; Tooltip()
    }
}

; ===================================================================================
;                                HELPER FUNCTIONS
; ===================================================================================

; Retrieves the keyboard layout identifier for the active window's thread.
GetKeyboardLayout() {
    ; We use DllCall to interact with the Windows API to get the current layout.
    return DllCall("GetKeyboardLayout", "UInt", 0, "UInt")
}

; Sends a message to the active window to change its keyboard layout.
ChangeKeyboardLayout(layout) {
    ; The PostMessage function sends a WM_INPUTLANGCHANGEREQUEST message (0x50)
    ; to the active window ('A'), requesting it to switch to the specified layout.
    PostMessage(0x50, 0, layout, , "A")
    
    ; The line below is an alternative method, often used for creating a new layout if it's not loaded.
    ; DllCall("LoadKeyboardLayout", "Str", layout, "UInt", 1)
}