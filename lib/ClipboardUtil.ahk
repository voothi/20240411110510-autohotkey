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
    ; If followed by common German conjunctions, it's likely a compositional hyphen.
    ; In those cases, we keep the hyphen and add a space instead of joining.
    text := RegExReplace(text, "((?<!\s)[" . marks . "])\s*\r?\n\s*(?=" . conjunctions . "\b)", "$1 ")
    
    ; Standard hyphenated word breaks (remove hyphen and join).
    text := RegExReplace(text, "[" . marks . "]\s*\r?\n\s*", "")
    
    ; 2. Replace remaining newlines with spaces.
    text := RegExReplace(text, "\r?\n", " ")
    
    ; 3. Remove HTML tags
    text := RegExReplace(text, "<[^<]+?>", "")
    
    ; 4. Replace multiple spaces with a single space
    text := RegExReplace(text, "\s{2,}", " ")
    
    ; 5. Remove space before punctuation marks
    text := RegExReplace(text, "\s+([:;,.!?])", "$1")
    
    ; 6. Remove non-printable characters (ZID: 20260505122804)
    text := RegExReplace(text, "[\x00-\x1F\x7F-\x9F]", "")
    
    ; 7. Handle special symbols and &nbsp; nuances
    text := RegExReplace(text, " (<br>|<br> )", " ")
    text := RegExReplace(text, "&\w+;", "")

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

/**
 * Converts clipboard text to upper or lower case with basic cleaning.
 */
ConvertClipboardCase(mode := "upper") {
    text := A_Clipboard
    ; 1. Remove HTML tags
    text := RegExReplace(text, "<[^<]+?>", "")
    ; 2. Remove non-printable characters
    text := RegExReplace(text, "[\x00-\x1F\x7F-\x9F]", "")
    ; 3. Replace newline characters with spaces, except when followed by whitespace
    text := RegExReplace(text, "\n(?!\s)", " ")
    
    if (mode = "upper")
        return StrUpper(text)
    else
        return StrLower(text)
}
