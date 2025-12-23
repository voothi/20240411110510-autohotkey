#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Google AI Studio Newline Hotfix
;
; Description:  This script remaps the Enter and Ctrl+Enter keys specifically for
;               Google AI Studio and the Antigravity application.
;               Many AI chat interfaces use Enter to submit and Shift+Enter to create
;               a new line. This script inverts that behavior for a more traditional
;               text-editing experience.
;
;               - Pressing Enter will now create a new line (sends Shift+Enter).
;               - Pressing Ctrl+Enter will now submit the prompt (sends Enter).
; ===================================================================================

; Google AI Studio
#HotIf WinActive("ahk_exe chrome.exe") and InStr(WinGetTitle("A"), "Google AI Studio")

; Remap the Enter key to send Shift+Enter (New Line).
Enter:: Send "+{Enter}"

; Remap Ctrl+Enter to send Enter (Submit).
^Enter:: Send "{Enter}"

; Antigravity Application
#HotIf WinActive("ahk_exe Antigravity.exe")

; Remap the Enter key to send Shift+Enter (New Line).
Enter:: Send "+{Enter}"

; Remap Shift+Enter to send Enter (Submit).
; This provides a keyboard way to submit in Chat, while Enter creates a new line.
+Enter:: Send "{Enter}"

; Note: Ctrl+Enter is NOT remapped here, so it retains its native function (e.g., Commit).

; Reset the context-sensitive directive. Any hotkeys defined below this line
; will be global again.
#HotIf