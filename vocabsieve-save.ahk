#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Vocabsieve Smart Save As
; Hotkey:       Ctrl + Alt + S (^!s)
;
; Description:  This script automates a "Save As" workflow within the Vocabsieve
;               application. It copies the content of a focused text field and
;               then uses that content to automatically populate the filename in the
;               "Save As" dialog.
;
; Target App:   Vocabsieve
;
; IMPORTANT:    This script relies on a fixed sequence of keystrokes and UI
;               behavior. If the Vocabsieve application's UI changes in a future
;               update, this script may need to be adjusted.
; ===================================================================================

^!s::
{
    ; First, click to ensure the target text field or UI element has focus.
    Click()
    
    ; --- Step 1: Copy the content of the focused field ---
    ; Move the cursor to the beginning of the line to ensure a complete selection.
    Send("{Home}")
    Sleep(200)
    
    ; Select all text in the field.
    Send("^a")
    Sleep(200)
    
    ; Copy the selected text to the clipboard.
    Send("^c")
    Sleep(200)
    
    ; --- Step 2: Open the 'Save As' dialog ---
    Send("^s")
    Sleep(200)
    
    ; --- Step 3: Prepare the filename input field ---
    ; This space-then-backspace trick is used to reliably clear and activate
    ; the filename box, ensuring the paste will overwrite any default name.
    Send("{Space}")
    Send("{Backspace}")
    
    ; A significant pause to allow the 'Save As' dialog to fully load and become responsive.
    Sleep(1000)
    
    ; --- Step 4: Paste the copied content as the new filename ---
    Send("^v")
}