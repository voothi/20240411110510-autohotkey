#Requires AutoHotkey v2.0

/**
 * Cleans the text: handles word hyphenation, removes HTML tags,
 * extra spaces, and other unnecessary characters. 
 * Ported from: https://github.com/voothi/20240310195111-remove-newline-util
 * Base logic: remove_newline_util.py (ZID: 20260503131400)
 */
CleanClipboardText(text) {
    conjunctions := "(?:und|oder|sowie|bzw|bis)"
    marks := "-¬"
    
    ; 1. Handle hyphenated word breaks.
    ; If followed by common German conjunctions, it's likely a compositional hyphen.
    ; In those cases, we keep the hyphen and add a space instead of joining.
    text := RegExReplace(text, "((?<!\s)[" . marks . "])\s*\r?\n\s*(?=" . conjunctions . "\b)", "$1 ")
    
    ; Standard hyphenated word breaks (remove hyphen and join).
    text := RegExReplace(text, "[" . marks . "]\s*\r?\n\s*", "")

    ; Also handle the case where the symbol is present but followed by a space on the same line,
    ; if it's clearly intended as a hyphen (common in some PDF extractions).
    ; Refinement: Don't join if preceded by a space (likely a dash) 
    ; or followed by a common conjunction (German compositional hyphen).
    text := RegExReplace(text, "(?<!\s)[" . marks . "]\s+(?!" . conjunctions . "\b)", "")
    
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
 * Waits for physically pressed modifier keys (Ctrl, Alt, Shift, Win) to be released
 * to prevent race conditions and modifier "bleed" during simulated keystrokes.
 */
WaitForModifiers() {
    if GetKeyState("Ctrl", "P")
        KeyWait("Ctrl")
    if GetKeyState("Alt", "P")
        KeyWait("Alt")
    if GetKeyState("Shift", "P")
        KeyWait("Shift")
    if GetKeyState("LWin", "P")
        KeyWait("LWin")
    if GetKeyState("RWin", "P")
        KeyWait("RWin")
}

/**
 * Tries to copy selected text. If no text is selected, it preserves the existing clipboard.
 * Returns true if the clipboard contains content (newly copied or preserved).
 */
SmartCopy(timeout := 0.5, shouldWait := true) {
    ; Local helper to extract selected text from an Internet Explorer_Server control via COM
    GetIESelectedText(hwnd) {
        try {
            msg := DllCall("RegisterWindowMessage", "Str", "WM_HTML_GETOBJECT")
            lResult := 0
            if DllCall("SendMessageTimeout", "Ptr", hwnd, "UInt", msg, "Ptr", 0, "Ptr", 0, "UInt", 2, "UInt", 1000, "Ptr*", &lResult) {
                IID_IHTMLDocument2 := Buffer(16)
                DllCall("ole32\CLSIDFromString", "WStr", "{332C4425-26CB-11D0-B483-00C04FD90119}", "Ptr", IID_IHTMLDocument2)
                
                pDoc := 0
                if !DllCall("oleacc\ObjectFromLresult", "Ptr", lResult, "Ptr", IID_IHTMLDocument2, "Ptr", 0, "Ptr*", &pDoc) {
                    if (pDoc) {
                        doc := ComValue(9, pDoc, 1)
                        if (doc) {
                            ; Try legacy selection mode first, then fall back to HTML5 standards mode
                            try {
                                return doc.selection.createRange().text
                            } catch {
                                try {
                                    return doc.parentWindow.getSelection().toString()
                                } catch {
                                    return ""
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            return ""
        }
        return ""
    }

    if (shouldWait) {
        WaitForModifiers()
    }
    OldClip := A_Clipboard
    A_Clipboard := ""
    
    ieTextCopied := false
    try {
        focusedHwnd := 0
        try {
            focusedHwnd := ControlGetFocus("A")
        } catch {
            ; Fallback: attempt to find the first IE control in the active window
            try {
                focusedHwnd := ControlGetHwnd("Internet Explorer_Server1", "A")
            } catch {
            }
        }
        
        if (focusedHwnd && WinGetClass(focusedHwnd) == "Internet Explorer_Server") {
            ieText := GetIESelectedText(focusedHwnd)
            if (ieText != "") {
                A_Clipboard := ieText
                ieTextCopied := true
            }
        }
    } catch {
    }
    
    if (!ieTextCopied) {
        ; Using SendEvent for better reliability in some target applications
        SendEvent("^c")
    }
    
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
