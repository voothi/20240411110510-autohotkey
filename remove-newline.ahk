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

#Include "Lib\ClipboardUtil.ahk"
^!N::
{
    ; Step 1: Capture the text to process.
    ; SmartCopy tries to copy the selection, but falls back to the existing clipboard 
    ; content if no text is selected.
    if !SmartCopy()
        return

    ; Execute the external Python script to process the clipboard content.
    RunWait("C:\Python\Python312\python.exe U:\voothi\20240310195111-remove-newline-util\remove_newline_util.py", "", "Hide")
    
    ; CRITICAL: Wait for the user to release the modifier keys (Alt and Control).
    ; If these are still held down, the application might see "Ctrl+Alt+V" instead 
    ; of "Ctrl+V", which often results in nothing being pasted.
    KeyWait "Alt"
    KeyWait "Control"

    ; Step 3: Paste the modified, single-line text from the clipboard.
    Send("^v")
}