#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Text-to-Speech (TTS) Hotkeys
; Hotkeys:      Ctrl+Alt+Shift+2 (English)
;               Ctrl+Alt+Shift+3 (German)
;               Ctrl+Alt+Shift+4 (Russian)
;
; Description:  This script provides multi-language Text-to-Speech functionality for
;               any selected text. It uses separate hotkeys to read the text aloud
;               in different languages by passing it to an external TTS engine
;               (Piper TTS) via a Python script.
;
; Dependencies:
;   - Python 3 must be installed.
;   - The `piper_tts.py` script and the Piper TTS engine must be set up.
;   - IMPORTANT: You MUST update the paths in the RunWait command below to match
;     your system's configuration.
; ===================================================================================

; #Persistent ; Ensures the script stays running. Note: In AHKv2, this is generally
              ; not needed for scripts that contain hotkeys, as they make it persistent by default.

; A reusable function that copies the selected text and runs the TTS Python script,
; passing the specified language code.
; @param lang: The language code (e.g., "en", "de") to be passed to the TTS script.
RunPythonScript(lang) {
    ; Step 1: Copy the selected text to the clipboard.
    Send("^c")
    ClipWait(1) ; Wait up to 1 second for the copy to complete.

    ; Step 2: Execute the external Python TTS script.
    ; The `lang` parameter is passed as an argument to `--lang`.
    ; The `--clipboard` argument tells the Python script to read its text from the clipboard.
    ; `RunWait` pauses this AHK script until the TTS playback is finished.
    ; `Hide` prevents a command window from appearing.
    RunWait("C:/Python/Python312/python.exe U:/voothi/20241206010110-piper-tts/piper_tts.py --lang " lang " --clipboard", "", "Hide")
    
    ; A pause after the script finishes. This might be useful if the TTS engine needs
    ; time to release resources. Can be adjusted or removed.
    Sleep(1000)
}


; --- Hotkey Definitions ---
; Each hotkey calls the main function with a different language code.

^!+2::RunPythonScript("en") ; Hotkey for English TTS.
^!+3::RunPythonScript("de") ; Hotkey for German TTS.
^!+4::RunPythonScript("ru") ; Hotkey for Russian TTS.