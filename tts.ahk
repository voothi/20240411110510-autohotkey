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

; Update Tray Menu to show current language
UpdateTrayMenu() {
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
}

SetLanguage(lang) {
    global currentLang := lang
    UpdateTrayMenu()
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
