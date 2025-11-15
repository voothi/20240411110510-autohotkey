#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Timestamp Inserter
; Hotkey:       Ctrl + Shift + / (^+/)
;
; Description:  This script provides a quick way to insert a timestamp in the
;               format YYYYMMDDHHMMSS (e.g., 20231115215309). This is very
;               useful for creating unique identifiers for notes (like in
;               Zettelkasten systems), logging, or generating unique filenames.
; ===================================================================================

^+/::
{
    ; Get the current date and time, formatted as a continuous string:
    ; Year(YYYY)Month(MM)Day(DD)Hour(HH)Minute(MM)Second(SS).
    TimeString := FormatTime("", "yyyyMMddHHmmss")
    
    ; Instantly type the generated timestamp string.
    SendInput TimeString
}