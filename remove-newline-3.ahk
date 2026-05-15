#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Remove Newlines Utility
; Hotkeys:      
;   - Ctrl + Alt + N (^!N): Process SELECTED text
;   - Ctrl + Alt + X (^!X): Process text ALREADY on clipboard
;
; Description:  This script cleans up text by removing newline characters using an
;               external Python script. It can either copy a new selection or use
;               the current clipboard content.
;
; Dependencies:
;   - Python 3 must be installed.
;   - A Python script that removes newlines from clipboard content must exist.
;   - IMPORTANT: Update paths in the RunWait command below to match your system.
; ===================================================================================

; Hotkey to process SELECTED text
^!N::
{
    ; Step 1: Copy the selected text to the clipboard.
    Send("^c")
    if !ClipWait(1) ; Wait up to 1 second for the clipboard to contain data.
    {
        return
    }

    ; Step 2: Execute the external Python script to process the clipboard content.
    RunWait("C:\Python\Python312\python.exe U:\voothi\20240310195111-remove-newline-util\remove_newline_util.py", "", "Hide")
    
    Sleep(1000)

    ; Step 3: Paste the modified text.
    Send("^v")
}

; Hotkey to process text ALREADY on the clipboard
^!X::
{
    ; Step 1: Execute the external Python script on existing clipboard content.
    RunWait("C:\Python\Python312\python.exe U:\voothi\20240310195111-remove-newline-util\remove_newline_util.py", "", "Hide")
    
    Sleep(1000)

    ; Step 2: Paste the modified text.
    Send("^v")
}