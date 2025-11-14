#Requires AutoHotkey v2.0

; =================================================================================
; --- CONFIGURATION ---
; You MUST provide the full paths to your Python executable and your script here.
; =================================================================================

; Example: pythonPath := "C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe"
pythonPath := "C:\Python\Python312\python.exe"

; Example: scriptPath := "D:\Scripts\anki-search.py"
scriptPath := "C:\Tools\anki-search\anki-search.py"


; =================================================================================
; --- HOTKEY ---
; This script will only run when the GoldenDict window is active.
; ^!a stands for Ctrl + Alt + A. You can change this to your preferred shortcut.
; Symbols: ^ (Ctrl), ! (Alt), + (Shift), # (Win)
; =================================================================================

#HotIf WinActive("ahk_exe goldendict.exe")

^!a::
{
    ; 1. Save the current clipboard content to a temporary variable.
    local savedClipboard := A_ClipboardAll
    A_Clipboard := "" ; Clear the clipboard to ensure ClipWait works reliably.

    ; 2. Send a Ctrl+C command to copy the currently selected text.
    SendInput("^c")
    
    ; 3. Wait up to 1 second for the clipboard to contain new text.
    if !ClipWait(1)
    {
        MsgBox("Error: Could not copy the selected text.")
        Return ; Stop the script if copying failed.
    }

    ; 4. Build the full command to run the Python script silently.
    ;    It uses the --browse-clipboard argument to read the copied text.
    local command := '"' . pythonPath . '" "' . scriptPath . '" --browse-clipboard'
    Run(command,, "Hide") ; "Hide" prevents the black console window from appearing.

    ; 5. Restore the original clipboard content.
    ;    A short delay gives the Python script time to read the clipboard first.
    Sleep(300) 
    A_Clipboard := savedClipboard
}

#HotIf ; End the context-sensitive hotkey section.