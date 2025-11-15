#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Lute Web App Helper Hotkeys
;
; Description:  This script provides a set of hotkeys to control a specific web
;               application, presumably named "Lute", which appears to have a main
;               "Reading" tab and related "Translate" or "Text Input" tabs.
;
;               The core logic is to allow the user to send commands to the main
;               "Reading" window, even when focused on one of the satellite windows.
;               If a hotkey is pressed in a "Translate" or "Text Input" tab, the
;               script will automatically Alt+Tab to the previous window (assumed
;               to be the "Reading" tab), send the command, and in some cases,
;               switch back.
; ===================================================================================


; --- F-Key Hotkeys (Status Setters) ---
; The following hotkeys (F1-F8) all share the same logic:
; 1. They only activate if a Chrome tab with "Reading", "Translate", or "Text Input"
;    in the title is the active window.
; 2. If the active tab is NOT the "Reading" tab, they send Alt+Tab to switch to it.
; 3. They then send a single-character command ('1'-'5', 'w', 'i', or 'x').

^!+F1:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        ; If the current window is not the main "Reading" window, switch to it.
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("1")
    }
}

^!+F2:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("2")
    }
}

^!+F3:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("3")
    }
}

^!+F4:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("4")
    }
}

^!+F5:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("5")
    }
}

^!+F6:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("w") ; "Well-known" status
    }
}

^!+F7:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("i") ; "Ignored" status
    }
}

^!+F8:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(500)
        }
        Send("x") ; "Unknown" status (example)
    }
}


; --- Macro Hotkeys (Complex Actions) ---
; These hotkeys perform a sequence of actions: switch window, send a command,
; switch back, and then trigger another hotkey for a final action.

^!+a:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        ; Step 1: Switch to the "Reading" window if not already active.
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(1000)
        }
        ; Step 2: Send the 'a' command (e.g., "Archive").
        Send("a")
        Sleep(1000)

        ; Step 3: Switch back to the original window if a switch occurred.
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(1000)
        }
        
        ; Step 4: Trigger another hotkey (e.g., for a dictionary lookup).
        ; Send("c") ; This line is commented out.
        Send("^!+1")
    }
}

^!+d:: {
    if (WinActive("ahk_exe chrome.exe") && (InStr(WinGetTitle("A"), "Reading") || InStr(WinGetTitle("A"), "Translate") || InStr(WinGetTitle("A"), "Text Input"))) {
        ; Step 1: Switch to the "Reading" window if not already active.
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(1000)
        }
        ; Step 2: Send the 'd' command (e.g., "Delete").
        Send("d")
        Sleep(1000)

        ; Step 3: Switch back to the original window if a switch occurred.
        if !InStr(WinGetTitle("A"), "Reading") {
            Send("!{Tab}")
            Sleep(1000)
        }
        
        ; Step 4: Trigger another hotkey.
        ; Send("c") ; This line is commented out.
        Send("^!+1")
    }
}