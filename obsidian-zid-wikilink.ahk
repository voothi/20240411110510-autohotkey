#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Obsidian ZID Wikilink Formatter
; Hotkey:       Ctrl + Alt + . (^!.)
;
; Description:  This script takes the currently selected text, runs it through an
;               external Python script to format it into an Obsidian-style
;               Zettelkasten ID (ZID) wikilink, and then pastes the result back.
;               For example, it might turn "My Awesome Note" into something like
;               "[[20251115215309 My Awesome Note]]".
;
; Dependencies:
;   - Python 3 must be installed.
;   - The `obsidian_zid_wikilink.py` script must exist at the specified path.
;   - IMPORTANT: You MUST update the paths in the RunWait command below to match
;     your system's configuration.
; ===================================================================================

; #Persistent ; Ensures the script stays running. Note: In AHKv2, this is generally
              ; not needed for scripts that contain hotkeys, as they make it persistent by default.

^!.::
{
    ; Step 1: Copy the selected text to the clipboard.
    Send("^c")
    ClipWait(1) ; Wait up to 1 second for the clipboard to contain the copied data.

    ; Step 2: Execute the external Python script to process the clipboard content.
    ; `RunWait` pauses this script's execution until the Python script has finished.
    ; The `Hide` option prevents a command window from appearing.
    RunWait("C:\Python\Python312\python.exe C:\Tools\obsidian-zid-wikilink\obsidian_zid_wikilink.py", "", "Hide")
    
    ; A pause after the external script finishes. This might be a safeguard for certain
    ; system-specific delays or to ensure the clipboard is updated properly.
    ; It can likely be adjusted or removed depending on your system's performance.
    Sleep(1000)

    ; Step 3: Paste the modified content from the clipboard, replacing the original selection.
    Send("^v")

    ; The commented-out line below could be used to add an additional delay after pasting, if needed.
    ; Sleep(1000)
}