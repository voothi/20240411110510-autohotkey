#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       GoldenDict Side/Pop-up Lookup
; Hotkey:       Ctrl + Alt + Shift + Q (^!+q)
;
; Description:  This script copies the selected text, cleans it by removing any
;               newline characters and handling German hyphenation in-process, 
;               and then triggers GoldenDict's global hotkey for its 
;               "scan pop-up" or "translate from clipboard" feature.
;
; Dependencies:
;   - ClipboardUtil.ahk must exist in the Lib folder.
;   - GoldenDict must be configured with a global hotkey for its pop-up feature.
;   - IMPORTANT: You MUST update the paths and hotkeys in this script to match
;     your system's configuration.
; ===================================================================================

#Include "Lib\ClipboardUtil.ahk"
#Include "*i Lib\GoldenDictLemmatizer.ahk"

^!+q::
{
    ; Step 1: Copy the currently selected text to the clipboard safely.
    ; Wait for all modifier keys to be physically released first.
    WaitForModifiers()

    ; Save existing clipboard and clear it. This signals
    ; kardenwort-window's PushWebviewSelectionToClipboard (which waits
    ; for an empty clipboard) to push the selected text.
    OldClip := A_Clipboard
    A_Clipboard := ""

    ; Allow time for PushWebviewSelectionToClipboard to finish its full
    ; cycle: JS DOM getSelection → set A_Clipboard → Sleep(400) → mode off.
    Sleep(600)

    ; If the clipboard was populated by PushWebviewSelectionToClipboard,
    ; use it directly. Otherwise fall back to SmartCopy (for non-kardenwort apps).
    if (Trim(A_Clipboard) == "") {
        A_Clipboard := OldClip
        SmartCopy(3, false)
    }

    if (Trim(A_Clipboard) != "")
    {
        ; Clean the clipboard content in-process.
        ; This removes newlines and handles hyphenated words.
        cleaned := CleanClipboardText(A_Clipboard)

        try {
            lemFn := "LemmatizeWord"
            cleaned := %lemFn%(cleaned)
        }
        
        A_Clipboard := cleaned
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