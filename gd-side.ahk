#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       GoldenDict Side/Pop-up Lookup
; Hotkey:       Ctrl + Alt + Shift + Q (^!+q)
;
; Description:  This script copies the selected text, cleans it by removing any
;               newline characters using an external Python script, and then
;               triggers GoldenDict's global hotkey for its "scan pop-up" or
;               "translate from clipboard" feature.
;
; Dependencies:
;   - Python 3 must be installed.
;   - A Python script for removing newlines must exist at the specified path.
;   - GoldenDict must be configured with a global hotkey for its pop-up feature.
;   - IMPORTANT: You MUST update the paths and hotkeys in this script to match
;     your system's configuration.
; ===================================================================================

^!+q::
{
    ; Step 1: Copy the currently selected text to the clipboard.
    ; The commented-out lines below are alternative methods for copying.
    ; A_Clipboard := ""
    ; SendInput("{LControl Down}c{LControl Up}")
    SendInput("^c")

    ; Step 2: Proceed only if the copy operation was successful within 1 second.
    if ClipWait(1)
    {
        ; Run an external Python script to process the clipboard content.
        ; This is typically used to remove newline characters, which can interfere
        ; with lookups of multi-line selections.
        ; The 'Hide' option prevents the command window from appearing.
        RunWait('C:\Python\Python312\python.exe "C:\Tools\remove_newline_util\remove_newline_util.py"', '', 'Hide')
    }
    
    ; The commented-out Sleep is a potential delay, currently disabled.
    ; Sleep(100)

    ; Step 3: Trigger GoldenDict's "scan pop-up" or "translate from clipboard" feature.
    ; Note: This assumes `^!+n` is configured as the relevant global hotkey within
    ; GoldenDict's settings. You may need to change this to match your configuration.
    SendInput("^!+n")

    ; The block below contains commented-out code, likely from previous versions or
    ; for debugging purposes. It is not active.
    ; if ClipWait(1)
    ; {
    ;     ; Sleep(100)
    ;     ; SendInput("{LControl Down}c{LControl Up}")
    ;     ; SendInput("^c")
    ; }
}