#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Zettelkasten ID Note Title Formatter
; Hotkey:       Ctrl + Alt + ; (^!;)
;
; Description:  This script takes the currently selected text, runs it through an
;               external Python script to prepend a Zettelkasten ID (ZID), and
;               then pastes the result back. This is designed to quickly create
;               new note titles in systems like Obsidian. For example, it might
;               turn "My Awesome Note" into "20251115215309 My Awesome Note".
;
; Dependencies:
;   - Python 3 must be installed.
;   - The `zid_name.py` script must exist at the specified path.
;   - IMPORTANT: You MUST update the paths in the RunWait command below to match
;     your system's configuration.
; ===================================================================================

; #Persistent ; Ensures the script stays running. Note: In AHKv2, this is generally
              ; not needed for scripts that contain hotkeys, as they make it persistent by default.

^!;::
{
    ; Step 1: Copy the selected text to the clipboard.
    Send("^c")
    ClipWait(1) ; Wait up to 1 second for the clipboard to contain the copied data.

    ; Step 2: Execute the external Python script to process the clipboard content.
    ; `RunWait` pauses this script's execution until the Python script has finished.
    ; The `Hide` option prevents a command window from appearing.
    RunWait("C:\Python\Python312\python.exe U:\voothi\20240929203511-zid-name", "", "Hide")
    
    ; A pause after the external script finishes. This might be a safeguard for certain
    ; system-specific delays. It can likely be adjusted or removed.
    Sleep(1000)

    ; Step 3: Paste the modified content (the new ZID-prefixed title) from the clipboard.
    Send("^v")

    ; The commented-out line below could be used to add an additional delay after pasting, if needed.
    ; Sleep(1000)
}