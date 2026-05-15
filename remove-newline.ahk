#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Smart Remove Newlines Utility
; Hotkey:       Ctrl + Alt + X (^!X)
;
; Description:  A smart utility that handles both selection and existing clipboard:
;               1. It attempts to copy any currently selected text.
;               2. If a selection is found, it processes and replaces it.
;               3. If NO selection is found (e.g. cursor is just blinking), it 
;                  processes the text ALREADY on the clipboard and pastes it.
;
; Dependencies:
;   - Python 3 must be installed.
;   - A Python script that removes newlines from clipboard content must exist.
;   - IMPORTANT: Update paths in the RunWait command below to match your system.
; ===================================================================================

^!X::
{
    ; Save the current clipboard content in case we need to fall back to it.
    OriginalClipboard := A_Clipboard
    
    ; Clear the clipboard to detect if a "Copy" operation actually puts new text there.
    A_Clipboard := ""
    
    ; Step 1: Try to copy any currently selected text.
    ; We send ^c and wait a very short time.
    Send("^c")
    
    ; Wait up to 150ms for the clipboard to receive TEXT data.
    ; If it times out OR the result is still empty, we assume no selection exists.
    if !ClipWait(0.15, 0) or (A_Clipboard == "")
    {
        ; Restore the original clipboard content since nothing new was selected.
        A_Clipboard := OriginalClipboard
    }

    ; If the clipboard is empty (nothing copied and nothing was there initially), do nothing.
    if (A_Clipboard == "")
    {
        return
    }

    ; Step 2: Execute the external Python script to process the clipboard content.
    ; The script is expected to modify the clipboard in-place.
    RunWait("C:\Python\Python312\python.exe U:\voothi\20240310195111-remove-newline-util\remove_newline_util.py", "", "Hide")
    
    ; A generous pause to ensure the system and the target application are ready for the paste.
    Sleep(600)

    ; Step 3: Paste the modified text.
    Send("^v")
}