#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Remove Newlines from Clipboard
; Hotkey:       Ctrl + Alt + X (^!X)
;
; Description:  This script takes the text ALREADY on the clipboard, runs it through
;               an external Python script to remove all newline characters, and then
;               pastes the result back. This is useful when you have already copied
;               text and want to clean it up before pasting.
;
; Dependencies:
;   - Python 3 must be installed.
;   - A Python script that removes newlines from clipboard content must exist.
;   - IMPORTANT: You MUST update the paths in the RunWait command below to match
;     your system's configuration.
;
; Integration Note: This AHK script encapsulates a multi-step process (Process,
;                   Paste) into a single hotkey.
; ===================================================================================

; #Persistent ; Ensures the script stays running. Note: In AHKv2, this is generally
              ; not needed for scripts that contain hotkeys, as they make it persistent by default.

^!X::
{
    ; Step 1: Execute the external Python script to process the EXISTING clipboard content.
    ; `RunWait` pauses this script's execution until the Python script has finished.
    ; The `Hide` option prevents a command window from appearing.
    RunWait("C:\Python\Python312\python.exe U:\voothi\20240310195111-remove-newline-util\remove_newline_util.py", "", "Hide")
    
    ; A pause after the external script finishes.
    Sleep(1000)

    ; Step 2: Paste the modified, single-line text from the clipboard.
    Send("^v")
}