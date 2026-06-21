#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       GoldenDict Smart Find/Find Next
; Hotkey:       Ctrl+G
;
; Description:  This script overloads the Ctrl+G hotkey within GoldenDict to provide
;               a "smart find" feature. It differentiates between initiating a new
;               search and finding the next occurrence of the current search term.
;
; How it works:
; 1. First Press (with new text selected):
;    - The script copies the selected text and initiates a new search for it
;      (equivalent to Ctrl+C, Ctrl+F, Ctrl+V, Enter).
; 2. Subsequent Presses:
;    - If you press the hotkey again without changing the selection, or if nothing
;      is selected, the script simply presses F3 to trigger "Find Next".
; ===================================================================================

; Make the hotkey context-sensitive, active only when a GoldenDict window is active.
#HotIf WinActive("ahk_exe goldendict.exe")

; Assign the hotkey to a function. This allows us to use a static variable 
; to track the search term across multiple hotkey presses.
^g::FindNextInGoldenDict()

FindNextInGoldenDict()
{
    ; A static variable retains its value between function calls.
    ; This is how we remember the last thing we searched for.
    static lastSearchTerm := ""
    
    ; Preserve the user's current clipboard content.
    savedClip := A_Clipboard
    A_Clipboard := "" ; Clear the clipboard to ensure ClipWait works reliably.

    Sleep(500) ; A small delay can help ensure the active window correctly processes the ^c.
    Send("^c")
    
    ; Wait up to 0.5 seconds for the clipboard to contain text.
    if ClipWait(0.5)
    {
        currentSelection := A_Clipboard

        ; If the newly copied text is the same as our last search term (and not empty),
        ; it means the user wants to find the next occurrence.
        if (currentSelection == lastSearchTerm && currentSelection != "")
        {
            Send("{F3}") ; F3 is the standard key for "Find Next".
        }
        else ; Otherwise, this is a new search.
        {
            lastSearchTerm := currentSelection ; Store the new selection as the last search term.

            ; --- Lemmatization via kardenwort-lite ---
            inFile := A_Temp "\gd_in.txt"
            outFile := A_Temp "\gd_out.txt"
            
            if FileExist(inFile)
                FileDelete(inFile)
            FileAppend(currentSelection, inFile, "UTF-8")
            
            pythonScript := "U:\voothi\20241223170748-kardenwort\src\kardenwort\core\kardenwort_lite.py"
            RunWait('cmd.exe /c python "' pythonScript '" < "' inFile '" > "' outFile '"', , "Hide")
            
            if FileExist(outFile) {
                lemmatizedWord := FileRead(outFile, "UTF-8")
                FileDelete(outFile)
                if (lemmatizedWord != "")
                    currentSelection := lemmatizedWord
            }
            if FileExist(inFile)
                FileDelete(inFile)
            ; -----------------------------------------

            A_Clipboard := currentSelection ; Update clipboard with the lemmatized word for pasting
            ClipWait(0.5)

            Send("^f") ; Open the find dialog.
            Sleep(150)
            Send("^v") ; Paste the search term.
            Send("{Enter}")
        }
    }
    else
    {
        ; This block handles cases where ClipWait timed out (e.g., no text was selected).
        ; If there's a previous search term, we assume the user wants to "Find Next" for that term.
        if (lastSearchTerm != "")
        {
            Send("{F3}")
        }
    }

    ; Restore the user's original clipboard content.
    A_Clipboard := savedClip
}

; Reset the context-sensitive hotkey directive.
#HotIf