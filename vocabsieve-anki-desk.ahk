#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Vocabsieve Anki Export Helper
; Hotkey:       Ctrl + Alt + O (^!sc018)
;
; Description:  This script automates the process of sending an entry from the
;               Vocabsieve application to Anki. It triggers the export and then
;               navigates through the resulting dialog box to select a specific
;               deck or note type before the user has to do anything manually.
;
; Target App:   Vocabsieve (assumed to be `app.exe` or `app_win32.exe`)
;
; IMPORTANT:    This script relies on a fixed sequence of keystrokes. If the UI of
;               the Vocabsieve application changes in a future update, you may need
;               to adjust the number of `{Right}` and `{Tab}` presses below.
; ===================================================================================

; #Persistent ; Ensures the script stays running. Note: In AHKv2, this is generally
              ; not needed for scripts that contain hotkeys, as they make it persistent by default.

; Define the hotkey using a scan code for reliability. sc018 corresponds to the 'O' key.
^!sc018::
{
    ; Only run if the Vocabsieve window is active.
    if WinActive("ahk_exe app.exe") || WinActive("ahk_exe app_win32.exe")
    {
        Sleep(200) ; A brief pause to ensure the application is ready for input.
        
        ; --- Step 1: Trigger the Export/Copy to Anki Action ---
        ; This sequence is assumed to open the Anki export dialog.
        
        ; The lines below are part of a previous or alternative sequence.
        ; Send("{Alt}")
        ; Sleep(200)
        ; Send("{Right}")
        ; Sleep(200)

        ; Send Alt+C, likely the shortcut for "Copy to Anki".
        Send("!{c}")
        Sleep(200)
        
        ; Send Enter to confirm the initial action.
        Send("{Enter}")
        Sleep(200)
        
        ; --- Step 2: Navigate the Anki Dialog Box ---
        ; The following keystrokes are designed to navigate the dialog that appears
        ; after the export is triggered.
        
        ; The lines below are part of a previous or alternative sequence.
        ; Send("{Enter}")
        ; Sleep(200)
        ; Sleep(200)
        
        ; Navigate horizontally (e.g., across radio buttons or tabs).
        Send("{Right}")
        Sleep(200)
        Send("{Right}")
        Sleep(200)
        Send("{Right}")
        Sleep(200)
        
        ; Move focus down to a different control (e.g., a deck selector).
        Send("{Tab}")
        Sleep(200)
        Send("{Tab}")
        Sleep(200)
        Send("{Tab}")
        Sleep(200)
        
        ; --- Step 3: Open the Target Dropdown Menu ---
        ; Send Alt+Down to open the dropdown list for the currently focused control.
        Send("!{Down}")
        Sleep(200)
    }
}