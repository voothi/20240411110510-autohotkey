#Requires AutoHotkey v2.0
#Include ..\Lib\Security.ahk

; ===================================================================================
; Script:       Multi-Provider Translate Selection (translate-selection.ahk)
; Description:  The main runtime script for hotkey-based text translation.
;
; Functionality:
;   1.  **Hotkey Action**: Trigger (e.g., Ctrl+Alt+F2) passes Source/Target language.
;   2.  **Selection Capture**: Copies selected text to Clipboard.
;   3.  **Secure Key Retrieval**:
;       - Reads `settings.ini` to locate `secrets.ini`.
;       - Fetches the obfuscated API key.
;       - Decrypts it in memory using `Lib/Security.ahk`.
;       - If decryption fails (no '%%SEC%%' marker), it falls back to using the text as-is.
;   4.  **Translation**: Executes a Python CLI wrapper (`deep-translator`) with the key.
;   5.  **Output**: Replaces the selected text on screen with the translation.
;
; Features:
;   - **Provider Cycling**: Press the trigger again to switch providers (if multiple defined).
;   - **Smart Newlines**: Preserves paragraph structure using tokens.
;   - **Security**: Never writes the decrypted key to disk; passes it to Python process only.
;
; Hotkeys:
;   Ctrl + Alt + F2: ru -> en
;   Ctrl + Alt + F3: ru -> de
;   Ctrl + Alt + F4: en -> ru
;   Ctrl + Alt + F5: de -> ru
; ===================================================================================

; Settings
PreserveNewlines := true ; Set to false to flatten text before translation
NewlineToken := "[[@@@]]" ; Token to preserve line breaks (characters inside \Q...\E are treated literally)

; Configuration and Providers
; Configuration and Providers
SettingsFile := A_ScriptDir . "/settings.ini"
PythonPath := "C:/Tools/deep-translator/venv/Scripts/python.exe"
ScriptPath_Google := "C:/Tools/deep-translator/translate.py"
ScriptPath_DeepL := "C:/Tools/deep-translator/translate.1.py"

GetGoogleCommand(text, src, tgt, outFile) {
    return A_ComSpec ' /c chcp 65001 > nul && "' . PythonPath . '" "' . ScriptPath_Google . '" --text ' . EscapeCmdArg(
        text) .
    ' --source ' . src . ' --target ' . tgt . ' > "' . outFile . '"'
}

GetDeepLCommand(text, src, tgt, outFile) {
    apiKey := GetDeepLKey()
    if (apiKey == "") {
        return ""
    }
    return A_ComSpec ' /c chcp 65001 > nul && "' . PythonPath . '" "' . ScriptPath_DeepL . '" --text ' . EscapeCmdArg(
        text) .
    ' --source ' . src . ' --target ' . tgt . ' --deepl-api-key "' . apiKey . '" > "' . outFile . '"'
}

EscapeCmdArg(str) {
    result := ""
    backslashes := 0
    loop parse, str {
        if (A_LoopField == "\") {
            backslashes += 1
        } else if (A_LoopField == '"') {
            ; Escape all preceding backslashes (double them)
            loop backslashes * 2
                result .= "\"
            backslashes := 0
            result .= '\"' ; Escape the quote
        } else {
            ; Non-special character, flush accumulated backslashes normally
            loop backslashes
                result .= "\"
            backslashes := 0
            result .= A_LoopField
        }
    }
    ; Handle trailing backslashes before the closing quote
    loop backslashes * 2
        result .= "\"

    return '"' . result . '"'
}

GetDeepLKey() {
    ; 1. Try secure settings
    Salt := IniRead(SettingsFile, "Security", "Salt", "")
    SecretsPath := IniRead(SettingsFile, "Security", "SecretsPath", "")

    ; Default secure path if not specified but salt exists (or implied)
    if (SecretsPath == "") {
        SecretsPath := EnvGet("USERPROFILE") . "\.translate-selection\secrets.ini"
    }

    if FileExist(SecretsPath) {
        ObfuscatedKey := IniRead(SecretsPath, "DeepL", "Key", "")
        if (ObfuscatedKey != "") {
            ; Attempt to decrypt
            Decrypted := Security.Deobfuscate(ObfuscatedKey, Salt)

            ; Check for internal magic marker "%%SEC%%"
            ; This confirms the decryption was successful and the key was indeed encrypted.
            if (SubStr(Decrypted, 1, 7) == "%%SEC%%") {
                return Trim(SubStr(Decrypted, 8)) ; Return the actual key, trimmed
            }

            ; If marker not found, assume the key in the file is Plain Text
            return Trim(ObfuscatedKey)
        }
    }

    ; 2. Fallback to legacy local secrets.ini
    LegacyFile := A_ScriptDir . "/secrets.ini"
    if FileExist(LegacyFile) {
        return IniRead(LegacyFile, "DeepL", "Key", "")
    }

    MsgBox "DeepL API Key not found.`nPlease run setup-security.ahk to configure secure storage."
    return ""
}

Providers := [GetGoogleCommand, GetDeepLCommand]

class TranslationSession {
    static SourceText := ""
    static CurrentProvider := 1
    static LastHotkey := ""
    static Active := false

    static Reset() {
        this.SourceText := ""
        this.CurrentProvider := 1
        this.LastHotkey := ""
        this.Active := false
    }
}

; Ru -> En
^!F2:: TranslateSelection("ru", "en")

; Ru -> De
^!F3:: TranslateSelection("ru", "de")

; En -> Ru
^!F4:: TranslateSelection("en", "ru")

; De -> Ru
^!F5:: TranslateSelection("de", "ru")

TranslateSelection(SourceLang, TargetLang) {
    ; Clear clipboard for ClipWait detection
    A_Clipboard := ""

    ; Copy selected text
    SendInput "^c"
    if !ClipWait(1) {
        MsgBox "No text selected or copy failed."
        TranslationSession.Reset()
        return
    }

    CurrentText := A_Clipboard

    ; Check if we are cycling
    ; Conditions: Active Session AND Same Hotkey AND Text matches original source
    if (TranslationSession.Active
        && A_ThisHotkey == TranslationSession.LastHotkey
        && CurrentText == TranslationSession.SourceText) {

        ; Cycle to next provider
        TranslationSession.CurrentProvider += 1
        if (TranslationSession.CurrentProvider > Providers.Length)
            TranslationSession.CurrentProvider := 1

        InputText := CurrentText
    } else {
        ; Start New Session
        TranslationSession.Reset()
        TranslationSession.Active := true
        TranslationSession.LastHotkey := A_ThisHotkey
        TranslationSession.CurrentProvider := 1
        TranslationSession.SourceText := CurrentText

        InputText := CurrentText
    }

    ; Prepare text for CLI
    ProcessText := InputText

    ; Tokenize Double Spaces (Indentation) to separate tokens __IDT__
    ; We use a "Constant Variable" look (UPPERCASE with underscores) which DeepL reliably duplicates without translating.
    ProcessText := StrReplace(ProcessText, "  ", "__IDT__")

    ; DeepL Specific: Tokenize Backslashes to __BSL__
    if (TranslationSession.CurrentProvider == 2) {
        ProcessText := StrReplace(ProcessText, "\", "__BSL__")
    }

    if (PreserveNewlines) {
        ; Use a distinct token which is less likely to be interpreted as grammar
        ; We do NOT pad it with spaces, to strictly preserve existing indentation/whitespace.
        Token := NewlineToken
        ProcessText := StrReplace(ProcessText, "`r`n", Token)
        ProcessText := StrReplace(ProcessText, "`n", Token)
        ProcessText := StrReplace(ProcessText, "`r", Token)
    } else {
        ; Flatten text for CLI (single line)
        ProcessText := StrReplace(ProcessText, "`r`n", " ")
        ProcessText := StrReplace(ProcessText, "`n", " ")
        ProcessText := StrReplace(ProcessText, "`r", " ")
    }

    ; Quote escaping is now handled by EscapeCmdArg in the command generator

    ; Temporary file for capturing output
    OutputFile := A_Temp . "\ahk_translate_out.txt"
    if FileExist(OutputFile)
        FileDelete OutputFile

    ; Get command for current provider
    ProviderFunc := Providers[TranslationSession.CurrentProvider]
    CommandStr := ProviderFunc(ProcessText, SourceLang, TargetLang, OutputFile)

    if (CommandStr == "")
        return

    ; Run the command hidden
    try {
        RunWait CommandStr, , "Hide"
    } catch as err {
        MsgBox "Failed to run translation script: " . err.Message
        return
    }

    ; Read the output
    if FileExist(OutputFile) {
        try
        {
            ; Read with UTF-8 encoding
            TranslatedText := FileRead(OutputFile, "UTF-8")
            TranslatedText := Trim(TranslatedText, " `t`r`n")

            ; DeepL Specific Restore: __BSL__ -> \
            if (TranslationSession.CurrentProvider == 2) {
                TranslatedText := RegExReplace(TranslatedText, "i)\s*__BSL__\s*", "\")

                ; Fix Python f-string/r-string spacing artifact (e.g. f "string" -> f"string")
                TranslatedText := RegExReplace(TranslatedText, "i)\b([frub])\s+`"", "$1`"")
            }

            ; Global Restore: __IDT__ -> "  " (Double Space)
            TranslatedText := RegExReplace(TranslatedText, "i)\s*__IDT__\s*", "  ")

            if (PreserveNewlines) {
                ; Remove newlines completely to avoid any spacing artifacts
                TranslatedText := StrReplace(TranslatedText, "`r`n", "")
                TranslatedText := StrReplace(TranslatedText, "`n", "")
                TranslatedText := StrReplace(TranslatedText, "`r", "")

                ; Restore newlines from the token
                ; Restore newlines from the token
                ; We use the normalized pattern '[[@+]]' to handle DeepL hallucinations (e.g. [[@@@@]])
                ; We removed space consumption `[ \t]?` to perfectly preserve indentation.
                TranslatedText := RegExReplace(TranslatedText, "i)\[\[@+\]\]", "`n")
            }

            if (TranslatedText != "") {
                ; Place result in clipboard and paste
                A_Clipboard := TranslatedText
                SendInput "^v"

                ; Restore original text to clipboard so user can use it
                Sleep 200
                A_Clipboard := TranslationSession.SourceText
            }
        }
        catch as err {
            MsgBox "Error reading output file: " . err.Message
        }

        ; Cleanup
        FileDelete OutputFile
    }
}
