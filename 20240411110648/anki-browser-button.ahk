; ^!+]:: {
;     If WinActive("ahk_exe anki.exe") {
;         Click()
;         Sleep(150)
;         Send("^a")
;         Sleep(150)
;         Send("^j")
;         Sleep(600)
;         Click()
;         Sleep(150)
;         Send("^!r")
;     }
; }

#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Switch to Anki Browser Window
; Hotkey:       Ctrl + Alt + I
;
; Description:  When the Anki "Preview" window is active, this script allows you
;               to quickly switch back to the main "Browse" window using the
;               hotkey.
; ===================================================================================

; The #HotIf directive makes the hotkey below active ONLY when a window
; with the title "Preview" belonging to the "anki.exe" process is active.
#HotIf WinActive("Preview ahk_exe anki.exe")

^!i::
{
    ; This command finds and activates the Anki "Browse" window.
    ;
    ; We use "RegEx:^Browse" because the full title of the browser window
    ; can change (e.g., "Browse (1 of 2014 cards selected)").
    ; This regular expression matches any window title that *starts with* "Browse"
    ; and belongs to the anki.exe process, making the script reliable.
    WinActivate("RegEx:^Browse ahk_exe anki.exe")
}

; Reset the context-sensitive directive so it doesn't affect other hotkeys
; you might add later in your script.
#HotIf