#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Remove Newlines from Selection
; Hotkey:       Ctrl + Alt + N (^!N)
;
; Description:  This script takes the currently selected text, runs it through an
;               external Python script to remove all newline characters, and then
;               pastes the result back as a single line of text. This is extremely
;               useful for cleaning up text copied from PDFs or websites with poor
;               formatting.
;
; Dependencies:
;   - Python 3 must be installed.
;   - A Python script that removes newlines from clipboard content must exist.
;   - IMPORTANT: You MUST update the paths in the RunWait command below to match
;     your system's configuration.
;
; Integration Note: This AHK script encapsulates a multi-step process (Copy, Process,
;                   Paste) into a single hotkey, which can simplify or replace
;                   complex macros in other tools like JoyToKey.
; ===================================================================================

; #Persistent ; Ensures the script stays running. Note: In AHKv2, this is generally
              ; not needed for scripts that contain hotkeys, as they make it persistent by default.

^!N::
{
    ; Step 1: Copy the selected text to the clipboard.
    Send("^c")
    ClipWait(1) ; Wait up to 1 second for the clipboard to contain the copied data.

    ; Step 2: Execute the external Python script to process the clipboard content.
    ; `RunWait` pauses this script's execution until the Python script has finished.
    ; The `Hide` option prevents a command window from appearing.
    RunWait("C:\Python\Python312\python.exe U:\voothi\20240310195111-remove-newline-util\remove_newline_util.py", "", "Hide")
    
    ; A pause after the external script finishes. This might be a safeguard for certain
    ; system-specific delays. It can likely be adjusted or removed.
    Sleep(1000)

    ; Step 3: Paste the modified, single-line text from the clipboard.
    Send("^v")

    ; The commented-out line below could be used to add an additional delay after pasting, if needed.
    ; Sleep(1000)
}