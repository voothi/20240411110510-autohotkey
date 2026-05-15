#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Smart Remove Newlines Utility
; Hotkey:       Ctrl + Alt + X (^!X)
;
; Description:  A smart utility that handles both selection and existing clipboard:
;               1. It attempts to copy any currently selected text.
;               2. If text is selected, it processes that selection.
;               3. If NO text is selected, it processes what is ALREADY on the clipboard.
;               4. The result is then pasted back.
;
; Dependencies:
;   - Python 3 must be installed.
;   - A Python script that removes newlines from clipboard content must exist.
;   - IMPORTANT: Update paths in the RunWait command below to match your system.
; ===================================================================================

^!X::
{
    ; Save the current clipboard content in case nothing new is selected.
    OriginalClipboard := A_Clipboard
    
    ; Clear the clipboard to detect if a copy operation actually occurs.
    A_Clipboard := ""
    
    ; Step 1: Try to copy any currently selected text.
    Send("^c")
    
    ; Wait up to 250ms for the clipboard to receive data from the copy command.
    if !ClipWait(0.25)
    {
        ; If nothing was copied (timeout), restore the original clipboard content.
        A_Clipboard := OriginalClipboard
    }

    ; If the clipboard is empty (nothing copied and nothing was there), exit early.
    if (A_Clipboard == "")
    {
        return
    }

    ; Step 2: Execute the external Python script to process the clipboard content.
    ; This script is expected to modify the clipboard content in-place.
    RunWait("C:\Python\Python312\python.exe U:\voothi\20240310195111-remove-newline-util\remove_newline_util.py", "", "Hide")
    
    ; A brief pause to ensure the Python script's changes are fully committed to the OS.
    Sleep(500)

    ; Step 3: Paste the modified text.
    Send("^v")
}