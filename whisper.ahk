#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Hotkey Forwarder
; Hotkey:       Ctrl + Alt + Shift + E (^!+E)
;
; Description:  This script acts as a simple hotkey forwarder or remapper. It
;               captures the `Ctrl+Alt+Shift+E` key combination and, in response,
;               sends the `Ctrl+Alt+E` combination.
;
;               This is useful for triggering a hotkey in another application using a
;               different set of keys, for example, if the original hotkey is
;               inconvenient or you want to create a custom mapping.
; ===================================================================================

; #Persistent ; Ensures the script stays running. Note: In AHKv2, this is generally
              ; not needed for scripts that contain hotkeys, as they make it persistent by default.

^!+E::
{
    ; This line sends the key combination Ctrl+Alt+E to the active window.
    Send("^!E")
}