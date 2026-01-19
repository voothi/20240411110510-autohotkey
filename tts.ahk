#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Text-to-Speech (TTS) Hotkeys
; Hotkeys:      Ctrl+Alt+Shift+2 (English)
;               Ctrl+Alt+Shift+3 (German)
;               Ctrl+Alt+Shift+4 (Russian)
;               Ctrl+Alt+Shift+5 (Ukrainian)
;
; Description:  This script provides multi-language Text-to-Speech functionality for
;               any selected text. It uses separate hotkeys to read the text aloud
;               in different languages by passing it to an external TTS engine
;               (Anki TTS CLI) via a Python script.
;
; Dependencies:
;   - Python 3 must be installed.
;   - The `anki-tts-cli.py` script must be set up.
;   - IMPORTANT: You MUST update the paths in the RunWait command below to match
;     your system's configuration.
;
; Related Repository: https://github.com/voothi/20260119103526-anki-tts-cli
; ===================================================================================

; Global variable to store current language
global currentLang := "en"
global currentHIcon := 0

; Update Tray Menu to show current language
UpdateTrayMenu() {
    global currentLang
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Current Language: " . currentLang, (*) => 0)
    A_TrayMenu.Disable("1&") ; Disable the first item (Current Language)
    A_TrayMenu.Add() ; Separator
    A_TrayMenu.Add("English (en)", (itemName, itemPos, MyMenu) => SetLanguage("en"))
    A_TrayMenu.Add("German (de)", (itemName, itemPos, MyMenu) => SetLanguage("de"))
    A_TrayMenu.Add("Russian (ru)", (itemName, itemPos, MyMenu) => SetLanguage("ru"))
    A_TrayMenu.Add("Ukrainian (uk)", (itemName, itemPos, MyMenu) => SetLanguage("uk"))
    A_TrayMenu.Add() ; Separator
    A_TrayMenu.AddStandard()
    
    UpdateTrayIcon()
}

SetLanguage(lang) {
    global currentLang := lang
    UpdateTrayMenu()
}

UpdateTrayIcon() {
    global currentLang, currentHIcon
    
    ; Mapping language to display text and colors (0xBBGGRR)
    langInfo := Map(
        "en", {text: "En", bg: 0xD83E00, fg: 0xFFFFFF}, ; Blue
        "de", {text: "De", bg: 0x00D7FF, fg: 0x000000}, ; Yellow
        "ru", {text: "Ru", bg: 0x0000FF, fg: 0xFFFFFF}, ; Red
        "uk", {text: "Uk", bg: 0xFFD700, fg: 0x000000}  ; Cyan
    )
    
    info := langInfo.Has(currentLang) ? langInfo[currentLang] : {text: "??", bg: 0x808080, fg: 0xFFFFFF}
    
    newHIcon := CreateIconFromText(info.text, info.bg, info.fg)
    if (newHIcon) {
        TraySetIcon("HICON:" . newHIcon)
        if (currentHIcon)
            DllCall("DestroyIcon", "Ptr", currentHIcon)
        currentHIcon := newHIcon
    }
}

CreateIconFromText(text, bgColor, textColor) {
    s := 16
    hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
    hMemDC := DllCall("CreateCompatibleDC", "Ptr", hDC, "Ptr")
    hBitmap := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", s, "Int", s, "Ptr")
    hOldBitmap := DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hBitmap, "Ptr")
    
    ; Draw background
    rect := Buffer(16, 0)
    NumPut("Int", 0, "Int", 0, "Int", s, "Int", s, rect)
    hBrush := DllCall("CreateSolidBrush", "UInt", bgColor, "Ptr")
    DllCall("FillRect", "Ptr", hMemDC, "Ptr", rect, "Ptr", hBrush)
    DllCall("DeleteObject", "Ptr", hBrush)
    
    ; Draw text
    DllCall("SetTextColor", "Ptr", hMemDC, "UInt", textColor)
    DllCall("SetBkMode", "Ptr", hMemDC, "Int", 1) ; Transparent
    
    hFont := DllCall("CreateFont", "Int", -11, "Int", 0, "Int", 0, "Int", 0, "Int", 700, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 3, "UInt", 2, "UInt", 1, "UInt", 34, "Str", "Arial Narrow", "Ptr")
    hOldFont := DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hFont, "Ptr")
    DllCall("DrawText", "Ptr", hMemDC, "Str", text, "Int", -1, "Ptr", rect, "UInt", 0x25)
    
    ; Create Icon
    iconInfo := Buffer(A_PtrSize == 8 ? 32 : 20, 0)
    NumPut("Int", 1, iconInfo, 0) ; fIcon = true
    hMask := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", s, "Int", s, "Ptr")
    NumPut("Ptr", hMask, iconInfo, A_PtrSize == 8 ? 16 : 12)
    NumPut("Ptr", hBitmap, iconInfo, A_PtrSize == 8 ? 24 : 16)
    
    hIcon := DllCall("CreateIconIndirect", "Ptr", iconInfo, "Ptr")
    
    ; Cleanup
    DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hOldBitmap)
    DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hOldFont)
    DllCall("DeleteObject", "Ptr", hMask)
    DllCall("DeleteObject", "Ptr", hBitmap)
    DllCall("DeleteObject", "Ptr", hFont)
    DllCall("DeleteDC", "Ptr", hMemDC)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
    
    return hIcon
}

UpdateTrayMenu() ; Initialize menu

; A reusable function that copies the selected text and runs the TTS Python script,
; passing the specified language code.
; @param lang: The language code (e.g., "en", "de") to be passed to the TTS script.
RunPythonScript(lang := "") {
    global currentLang
    if (lang != "") {
        currentLang := lang
        UpdateTrayMenu()
    } else {
        lang := currentLang
    }

    ; Step 1: Copy the selected text to the clipboard.
    Send("^c")
    ClipWait(1) ; Wait up to 1 second for the copy to complete.

    ; Step 2: Execute the external Python TTS script.
    ; Arguments: "text" "lang"
    ; `RunWait` pauses this AHK script until the TTS playback is finished.
    ; `Hide` prevents a command window from appearing.
    RunWait('C:\Python\Python312\python.exe U:\voothi\20260119103526-anki-tts-cli\anki-tts-cli.py "' A_Clipboard '" "' lang '"', "", "Hide")
    
    ; A pause after the script finishes. This might be useful if the TTS engine needs
    ; time to release resources. Can be adjusted or removed.
    Sleep(1000)
}


; --- Hotkey Definitions ---
; Each hotkey calls the main function with a different language code.

^!+2::RunPythonScript("en") ; Hotkey for English TTS.
^!+3::RunPythonScript("de") ; Hotkey for German TTS.
^!+4::RunPythonScript("ru") ; Hotkey for Russian TTS.
^!+5::RunPythonScript("uk") ; Hotkey for Ukrainian TTS.
; Mouse trigger: Middle button while Left button is held (during selection)
~LButton & MButton:: {
    RunPythonScript()
}
