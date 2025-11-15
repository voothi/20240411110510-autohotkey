#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Convert Selected Text to Uppercase
; Hotkey:       Ctrl + Alt + U (^!U)
;
; Description:  This script takes the currently selected text, runs it through an
;               external Python script to convert it to UPPERCASE, and then pastes
;               the result back, effectively replacing the selection with its
;               uppercase version.
;
; Dependencies:
;   - Python 3 must be installed.
;   - A Python script that modifies the clipboard content to uppercase must exist.
;   - IMPORTANT: You MUST update the paths in the RunWait command below to match
;     your system's configuration.
; ===================================================================================

; #Persistent ; Ensures the script stays running. Note: In AHKv2, this is generally
              ; not needed for scripts that contain hotkeys, as they make it persistent by default.

^!U::
{
    ; Step 1: Copy the selected text to the clipboard.
    Send("^c")
    ClipWait(1) ; Wait up to 1 second for the clipboard to contain the copied data.

    ; Step 2: Execute the external Python script to process the clipboard content.
    ; `RunWait` pauses this script's execution until the Python script has finished.
    ; The `Hide` option prevents a command window from appearing.
    RunWait("C:\Python\Python312\python.exe C:\Tools\uppercase_util\uppercase_util.py", "", "Hide")
    
    ; A pause after the external script finishes. This might be a safeguard for certain
    ; system-specific delays. It can likely be adjusted or removed.
    Sleep(1000)

    ; Step 3: Paste the modified, uppercased text from the clipboard.
    Send("^v")

    ; The commented-out line below could be used to add an additional delay after pasting, if needed.
    ; Sleep(1000)
}