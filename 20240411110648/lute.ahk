; GetKeyboardLayout() {
;     ; This function returns the current keyboard layout identifier
;     return DllCall("GetKeyboardLayout", "UInt", 0, "UInt")
; }

GetKeyboardLanguage() {
    ; This function returns the current keyboard layout language identifier
    layout := DllCall("GetKeyboardLayout", "UInt", 0, "UInt")
    ; Extract the language identifier (high-word)
    languageID := layout >> 16
    return languageID
}

; ChangeKeyboardLayout(layoutId) {
;     ; Changes the keyboard layout by allowing the system to load the specified layout
;     ; DllCall("LoadKeyboardLayout", "UInt", layoutId, "UInt", 1)
;     DllCall("LoadKeyboardLayout", "Str", layoutId, "UInt", 1)
; }

; ChangeKeyboardLayout(layoutId) {
;     ; Change the keyboard layout by sending a message to the system
;     ; The layoutId should be a string with the hexadecimal representation padded with zeros
;     layoutIdStr := Format("{:X}", layoutId)

;     ; DllCall to load the keyboard layout
;     DllCall("LoadKeyboardLayout", "Str", "0000" layoutIdStr, "UInt", 1)
; }

; ChangeKeyboardLayout(layoutId) {
;     ; Layout ID must be in the format "00000409" for English (US)
;     layoutIdStr := Format("{:08X}", layoutId)
;     result := DllCall("LoadKeyboardLayout", "Str", layoutIdStr, "UInt", 0x00000001)
;     if (result == 0) {
;         MsgBox("Failed to load keyboard layout. Error: " DllCall("GetLastError", "UInt"))
;     } else {
;         ; Optionally, activate the layout
;         DllCall("ActivateKeyboardLayout", "UInt", result, "UInt", 0)
;     }
;     return result
; }

ChangeKeyboardLanguage() {
    Send("{Shift down}{Alt down}{Shift up}{Alt up}")
}

; SwitchToEnglishLayoutIfNeeded() {
;     ; Get the current keyboard layout
;     currentLayout := GetKeyboardLayout()

;     ; Define layout identifiers for English (US)
;     englishLayout := 0x0409  ; English (United States)

;     ; Check if the current layout is not English
;     if (currentLayout != englishLayout) {
;         ChangeKeyboardLayout(englishLayout) ; Switch to English layout

;         ; Wait a moment to ensure the layout has changed
;         Sleep(100)

;         ; Optionally, debug output to confirm change
;         newLayout := GetKeyboardLayout()
;         Tooltip("New Layout Code: " newLayout)
;         Sleep(2000) ; Show the tooltip for 2 seconds
;         Tooltip() ; Clear the tooltip
;     }
; }

; SwitchToEnglishLayoutIfNeeded() {
;     ; Get the current keyboard layout
;     currentLayout := GetKeyboardLayout()

;     ; Define layout identifier for English (US)
;     englishLayout := 0x0409  ; English (United States)

;     ; Check if the current layout is not English
;     if (currentLayout != englishLayout) {
;         ; Attempt to change to English layout
;         newLayout := ChangeKeyboardLayout(englishLayout)

;         ; Display the current and new layout codes for debugging
;         Tooltip("Current Layout Code: " currentLayout " -> New Layout Code: " newLayout)
;         Sleep(2000) ; Show the tooltip for 2 seconds
;         Tooltip() ; Clear the tooltip

;         ; Optionally, log the change for further debugging
;         FileAppend("Switched Layout - Current: " currentLayout " New: " newLayout "`n", "LayoutSwitchLog.txt")
;     }
; }

SwitchToEnglishLayoutIfNeeded() {
    ; Get the current keyboard layout
    currentLanguage := GetKeyboardLanguage()

    ; Debugging: Display the current language ID
    Tooltip("Current Language Code: " currentLanguage)
    Sleep(2000) ; Show the tooltip for 2 seconds
    Tooltip() ; Clear the tooltip

    ; Define layout identifier for English (US)
    englishLanguage := "1033"  ; English (United States) 1033. 1049

    ; Check if the current layout is not English
    if (currentLanguage != englishLanguage) {
        ; Attempt to change to English layout
        ChangeKeyboardLanguage()

        ; Get the current keyboard layout
        nextLanguage := GetKeyboardLanguage()

        ; Debugging: Display the current language ID
        Tooltip("Current Language Code: " nextLanguage)
        Sleep(2000) ; Show the tooltip for 2 seconds
        Tooltip() ; Clear the tooltip

        ; Optionally, log the change for further debugging
        ; FileAppend("Switched Layout - Current: " currentLayout " New: " newLayout "`n", "LayoutSwitchLog.txt")
    }
}

; Optional: Set a timer to check every 10 seconds as a fallback; adjust as needed
SetTimer(SwitchToEnglishLayoutIfNeeded, 10000) ; Set a timer to call the function every 10 seconds

; Show initial layout for debugging
; initialLayout := GetKeyboardLayout()
; MsgBox("Initial Layout Code: " initialLayout)

^!+F1:: {
    ; First, try switching to the English layout if needed
    ; SwitchToEnglishLayoutIfNeeded()

    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
        InStr(WinGetTitle("A"), "Text Input"))) {
            ; Проверяем, не содержит ли название окна "Reading"
            if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("1")
    }
}

^!+F2:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("2")
    }
}

^!+F3:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("3")
    }
}

^!+F4:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("4")
    }
}

^!+F5:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("5")
    }
}

^!+F6:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("w")
    }
}

^!+F7:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("i")
    }
}

^!+F8:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("x")
    }
}

^!+a:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(1000)
        }
        Send("a")

        Sleep(1000)

        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(1000)
        }
        Send("c")
    }
}

^!+d:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") ||
    InStr(WinGetTitle("A"), "Text Input"))) {
        ; Проверяем, не содержит ли название окна "Reading"
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(1000)
        }
        Send("d")

        Sleep(1000)

        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(1000)
        }
        Send("c")
    }
}
