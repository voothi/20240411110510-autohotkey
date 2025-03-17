GetKeyboardLayout() {
    ; This function returns the current keyboard layout handle
    return DllCall("GetKeyboardLayout", "UInt", 0, "UInt")
}

GetLanguageID(layoutHandle) {
    ; Extract the language identifier (high-word) from the layout handle
    return layoutHandle >> 16
}

SwitchToEnglishLanguageIfNeeded() {
    ; Get the current keyboard layout handle
    currentLayout := GetKeyboardLayout()
    
    ; Debugging: Display the current layout handle
    Tooltip("Current Layout Handle: " currentLayout)
    Sleep(2000) ; Show the tooltip for 2 секунды
    Tooltip() ; Clear the tooltip
    
    ; Get the language identifier from the current layout handle
    currentLanguage := GetLanguageID(currentLayout)
    
    ; Debugging: Display the current language identifier
    Tooltip("Current Language ID: " currentLanguage)
    Sleep(2000) ; Show the tooltip for 2 секунды
    Tooltip() ; Clear the tooltip
    
    ; Define language identifiers for English (US) and Russian
    englishLanguage := 0x0409  ; English (United States)
    russianLanguage := 0x0419  ; Russian (Russia)
    
    ; Check if the current language is not English
    if (currentLanguage != englishLanguage) {
        ; Attempt to change to English language using Alt+Shift
        Send("{Shift down}{Alt down}{Shift up}{Alt up}")
        
        ; Optionally, wait a short time to ensure the change has been applied
        Sleep(100)
        
        ; Get the new keyboard layout handle after switching
        newLayout := GetKeyboardLayout()
        
        ; Retrieve the language identifier from the newly obtained layout handle
        newLanguage := GetLanguageID(newLayout)

        ; Debugging: Show the new layout handle and associated language identifier
        Tooltip("Switched to New Layout Handle: " newLayout "`nNew Language ID: " newLanguage)
        Sleep(2000) ; Display the tooltip for 2 seconds
        Tooltip() ; Clear the tooltip

        ; Optionally, log the layout change for future reference
        FileAppend("Switched Layout - Current: " currentLayout " New: " newLayout "`n", "LayoutSwitchLog.txt")
    } else {
        ; Debugging: Indicate that no change was necessary
        Tooltip("No change needed. Current Language ID: " currentLanguage)
        Sleep(2000) ; Display the tooltip for 2 seconds
        Tooltip() ; Clear the tooltip
    }
}

; Optional: Set a timer to check every 10 секунд as a fallback; adjust as needed
SetTimer(SwitchToEnglishLanguageIfNeeded, 10000) ; Set a timer to call the function every 10 секунд

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
