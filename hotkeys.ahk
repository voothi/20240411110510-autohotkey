#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Google AI Studio Newline Hotfix
;
; Description:  This script remaps the Enter and Ctrl+Enter keys specifically for
;               the Google AI Studio web interface (and similar web apps).
;               Many AI chat interfaces use Enter to submit and Shift+Enter to create
;               a new line. This script inverts that behavior for a more traditional
;               text-editing experience.
;
;               - Pressing Enter will now create a new line (sends Shift+Enter).
;               - Pressing Ctrl+Enter will now submit the prompt (sends Enter).
; ===================================================================================

; The following hotkeys are context-sensitive. They will only be active when a
; Google Chrome window is active AND its title contains "Google AI Studio".
#HotIf WinActive("ahk_exe chrome.exe") and InStr(WinGetTitle("A"), "Google AI Studio")

    ; Remap the Enter key to send Shift+Enter.
    ; This allows you to create new lines easily, just like in a standard text editor.
    Enter::Send "+{Enter}"

    ; Remap Ctrl+Enter to send a standard Enter keypress.
    ; This becomes the new "submit" hotkey.
    ^Enter::Send "{Enter}"

; Reset the context-sensitive directive. Any hotkeys defined below this line
; will be global again.
#HotIf