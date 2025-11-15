#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Advanced GoldenDict Lookup
; Hotkey:       Ctrl + Alt + Shift + 1 (^!+1)
;
; Description:  This script performs a lookup of the selected text in GoldenDict.
;               It intelligently finds and activates the main GoldenDict window,
;               pre-processes the selected text by removing newlines using a Python
;               script, and then pastes the cleaned text to perform the search.
;
; Dependencies:
;   - Python 3 must be installed.
;   - A Python script for removing newlines must exist.
;   - IMPORTANT: You MUST update the paths in the RunWait command below to match
;     your system.
; ===================================================================================

^!+1::
{
    ; Step 1: Copy the currently selected text to the clipboard.
    SendInput("^c")
    ClipWait(1) ; Wait up to 1 second for the copy action to complete.
    Sleep(100)

    ; --- Step 2: Find and Activate the Main GoldenDict Window ---
    main_gd_id := 0
    
    ; Iterate through all open GoldenDict windows to find the main one.
    for id in WinGetList("ahk_exe goldendict.exe")
    {
        ; Heuristic: Assume the main window is the one wider than 800 pixels.
        ; This helps distinguish it from small pop-up or scan windows.
        ; You may need to adjust this value based on your screen resolution.
        WinGetPos(,, &width,, id)
        if (width > 800)
        {
            main_gd_id := id
            break
        }
    }

    ; Handle the three possible states of the GoldenDict window.
    if (main_gd_id && WinGetID("A") == main_gd_id)
    {
        ; Case 1: The main window was found and is already the active window.
        ; No action is needed to activate it.
    }
    else if (main_gd_id)
    {
        ; Case 2: The main window was found but is not active. Activate it.
        WinActivate(main_gd_id)
        WinWaitActive(main_gd_id,, 2) ; Wait for activation to complete.
    }
    else
    {
        ; Case 3: The main window was not found (e.g., app is minimized to tray).
        ; Send GoldenDict's global hotkey to show/hide the main window.
        ; Note: This assumes "^!+m" is configured as the global hotkey in GoldenDict.
        SendInput("^!+m")
        WinWait("ahk_exe goldendict.exe",, 2)
        WinActivate()
    }

    ; Step 3: Focus the search input field in GoldenDict.
    ; !d is a common shortcut for this (Alt+D).
    SendInput("!d") 

    ; Step 4: Run an external Python script to clean the clipboard content.
    ; This script is expected to remove newline characters from the text.
    ; The 'Hide' option prevents the command window from appearing.
    RunWait('C:\Python\Python312\python.exe "C:\Tools\remove_newline_util\remove_newline_util.py"', '', 'Hide')
    Sleep(100)

    ; Step 5: Paste the cleaned text into the search bar and execute the search.
    SendInput("^v")
    Sleep(100)
    SendInput("{Enter}")
}