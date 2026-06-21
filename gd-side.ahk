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
^!+q::
{
    ; Step 1: Copy the currently selected text to the clipboard safely.
    if SmartCopy(3)
    {
        ; Clean the clipboard content in-process.
        ; This removes newlines and handles hyphenated words.
        cleaned := CleanClipboardText(A_Clipboard)

        ; --- Lemmatization via kardenwort-lite ---
        inFile := A_Temp . "\gd_in.txt"
        outFile := A_Temp . "\gd_out.txt"
        
        if FileExist(inFile)
            FileDelete(inFile)
        FileAppend(cleaned, inFile, "UTF-8")
        
        pythonScript := "U:\voothi\20241223170748-kardenwort\src\kardenwort\core\kardenwort_lite.py"
        RunWait('cmd.exe /c python "' . pythonScript . '" < "' . inFile . '" > "' . outFile . '" 2>&1', , "Hide")
        
        if FileExist(outFile) {
            lemmatizedWord := FileRead(outFile, "UTF-8")
            FileDelete(outFile)
            if (lemmatizedWord != "")
                cleaned := lemmatizedWord
        }
        if FileExist(inFile)
            FileDelete(inFile)
        ; -----------------------------------------

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