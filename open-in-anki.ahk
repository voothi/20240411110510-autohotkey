#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Anki Search from GoldenDict
;
; Description:  This script facilitates searching for selected text in Anki's card
;               browser. It has two modes of operation:
;
;               1. Command-Line Mode: Designed for integration with external programs
;                  like GoldenDict. You can configure GoldenDict to run this script
;                  with a "/trigger" argument to perform a search.
;
;               2. Hotkey Mode: Provides a manual hotkey (Ctrl+Alt+A) to search for
;                  the selected text while you are inside the GoldenDict window.
;
; Dependencies: - Python 3 must be installed.
;               - A specific Python script (`anki-search.py`) is required.
;               - IMPORTANT: You MUST update the paths below.
; ===================================================================================

; Allows the hotkey instance to run persistently while one-off command-line
; instances can be launched and closed without terminating the main script.
#SingleInstance Off 

; --- User Configuration ---
; You must update these paths to match your system's configuration.
pythonPath := "C:\Python\Python312\python.exe"
scriptPath := "C:\Tools\anki-search\anki-search.py"


; ===================================================================================
; === MODE 1: Command-Line Trigger (for GoldenDict integration) ===
; This block checks if the script was launched with a specific command-line argument.
; ===================================================================================
if A_Args.Length > 0 && A_Args[1] == "/trigger"
{
    ; When run this way, it's assumed that GoldenDict has already copied the
    ; desired text to the clipboard. We just need to execute the main logic.
    RunPythonAndActivateAnki()
    ExitApp ; This is crucial: it closes this temporary, one-off instance of the script.
}


; ===================================================================================
; === MODE 2: Hotkey Trigger (for manual use) ===
; This section defines the hotkey that runs in the background.
; ===================================================================================

; The hotkey is context-sensitive and will only work when GoldenDict is the active window.
#HotIf WinActive("ahk_exe goldendict.exe")
^!a::
{
    ; The commented-out lines below show a pattern for saving and restoring the
    ; clipboard if you want to ensure the user's original clipboard is not overwritten.
    ; local savedClipboard := A_ClipboardAll
    
    ; Copy the currently selected text.
    A_Clipboard := ""
    SendInput("^c")
    
    ; If copying fails (e.g., nothing selected), abort.
    if !ClipWait(1)
        Return

    ; Execute the main logic.
    RunPythonAndActivateAnki()

    ; Restore the user's original clipboard content.
    ; Sleep(300)
    ; A_Clipboard := savedClipboard
}
#HotIf


; ===================================================================================
; === CORE FUNCTION: Performs the search and activates Anki ===
; This function contains the shared logic used by both modes.
; ===================================================================================
RunPythonAndActivateAnki()
{
    ; Build the command to run the Python script, passing an argument that tells it
    ; to search for the content currently on the clipboard.
    local command := '"' . pythonPath . '" "' . scriptPath . '" --browse-clipboard'
    Run(command,, "Hide") ; Run the command in the background.

    ; After the Python script executes, wait for the Anki "Browse" window to appear.
    if WinWait("Browse ahk_exe anki.exe",, 2)
    {
        ; If the window appears, bring it to the foreground.
        WinActivate("Browse ahk_exe anki.exe")
    }
}