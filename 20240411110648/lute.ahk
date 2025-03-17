GetKeyboardLayout() {
    ; This function returns the current keyboard layout identifier
    ; We use DllCall to retrieve the layout
    return DllCall("GetKeyboardLayout", "UInt", 0, "UInt")
}

ChangeKeyboardLayout(layout) {
    ; Change the keyboard layout by using the DllCall to LoadKeyboardLayout
    ; DllCall("LoadKeyboardLayout", "Str", layout, "UInt", 1)
    PostMessage(0x50, 0, layout,, "A")  ; 0x50 is WM_INPUTLANGCHANGEREQUEST. Switch the active window's keyboard layout/language to English:
}

SwitchToEnglishLayoutIfNeeded() {
    ; Get the current keyboard layout
    currentLayout := GetKeyboardLayout()
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
        Tooltip("New Layout Code: " newLayout)
        Sleep(2000)
        Tooltip() ; Clear the tooltip after 2 seconds

        ; Get the new keyboard layout after the change
        ; newLayout := GetKeyboardLayout()

        ; Display the new layout code for debugging
        ; Tooltip("New Layout Code: " newLayout)
        ; Sleep(2000)
        ; Tooltip() ; Clear the tooltip after 2 seconds
    }
}

SetTimer(SwitchToEnglishLayoutIfNeeded, 10000) ; Set a timer to call the function every 2 minutes 120000

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
