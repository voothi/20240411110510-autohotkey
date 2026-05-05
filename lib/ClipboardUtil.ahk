#Requires AutoHotkey v2.0

/**
 * Cleans the text: handles word hyphenation, removes HTML tags,
 * extra spaces, and other unnecessary characters. 
 * Ported from remove_newline_util.py (ZID: 20260503131400)
 */
CleanClipboardText(text) {
    conjunctions := "(?:und|oder|sowie|bzw|bis)"
    marks := "[-¬]"
    
    ; 1. Handle hyphenated word breaks.
    ; Handles both \n and \r\n explicitly.
    text := RegExReplace(text, "((?<!\s)[" . marks . "])\s*\r?\n\s*(?=" . conjunctions . "\b)", "$1 ")
    text := RegExReplace(text, "[" . marks . "]\s*\r?\n\s*", "")
    
    ; 2. Replace remaining newlines with spaces.
    text := RegExReplace(text, "\r?\n", " ")
    
    ; 3. Remove HTML tags
    text := RegExReplace(text, "<[^<]+?>", "")
    
    ; 4. Replace multiple spaces with a single space
    text := RegExReplace(text, "\s{2,}", " ")
    
    ; 5. Remove space before punctuation marks
    text := RegExReplace(text, "\s+([:;,.!?])", "$1")
    
    ; 6. Remove non-printable characters (ported from Python)
    text := RegExReplace(text, "[\x00-\x1F\x7F-\x9F]", "")
    
    return Trim(text)
}

/**
 * Tries to copy selected text. If no text is selected, it preserves the existing clipboard.
 * Returns true if the clipboard contains content (newly copied or preserved).
 */
SmartCopy(timeout := 0.5) {
    OldClip := A_Clipboard
    A_Clipboard := ""
    
    ; Using SendEvent for better reliability in some target applications
    SendEvent("^c")
    
    if !ClipWait(timeout) {
        ; Fallback to existing clipboard if no selection captured.
        A_Clipboard := OldClip
    }
    
    ; Brief delay for system stability
    Sleep(100)
    
    return A_Clipboard != ""
}
