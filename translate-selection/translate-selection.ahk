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
;   - **Smart Newlines**: Preserves paragraph structure. Optional advanced tokenization.
;       - Controlled by `UseTokens=true` in `settings.ini`.
;       - Uses tokens `[[S]]`, `[[B]]`, `[[N]]` for robust DeepL handling.
;   - **Security**: Never writes the decrypted key to disk; passes it to Python process only.
;
; Related Repository: https://github.com/voothi/20241122093311-deep-translator
;
; Hotkeys:
;   Ctrl + Alt + F2: ru -> en
;   Ctrl + Alt + F3: ru -> de
;   Ctrl + Alt + F4: en -> ru
;   Ctrl + Alt + F5: de -> ru
; ===================================================================================

; Settings
PreserveNewlines := true ; Set to false to flatten text before translation

; Configuration and Providers
; Configuration and Providers
SettingsFile := A_ScriptDir . "/settings.ini"
PythonPath := "U:/voothi/20241122093311-deep-translator/venv/Scripts/python.exe"
ScriptPath_Google := "U:/voothi/20241122093311-deep-translator/translate_google.py"
ScriptPath_DeepL := "U:/voothi/20241122093311-deep-translator/translate_deepl.py"

GetGoogleCommand(text, src, tgt, outFile, errFile) {
    return A_ComSpec ' /c chcp 65001 > nul && "' . PythonPath . '" "' . ScriptPath_Google . '" --text ' . EscapeCmdArg(
        text) .
    ' --source ' . src . ' --target ' . tgt . ' > "' . outFile . '" 2> "' . errFile . '"'
}

GetDeepLCommand(text, src, tgt, outFile, errFile) {
    apiKey := GetDeepLKey()
    if (apiKey == "") {
        return ""
    }
    return A_ComSpec ' /c chcp 65001 > nul && "' . PythonPath . '" "' . ScriptPath_DeepL . '" --text ' . EscapeCmdArg(
        text) .
    ' --source ' . src . ' --target ' . tgt . ' --deepl-api-key "' . apiKey . '" > "' . outFile . '" 2> "' . errFile . '"'
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

    return ""
}

Providers := [GetGoogleCommand, GetDeepLCommand]
ProviderNames := ["Google", "DeepL"]

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
    ; Handle whitespace preservation based on settings
    TrimWhitespace := IniRead(SettingsFile, "Settings", "TrimWhitespace", "false")
    LeadingWS := ""
    TrailingWS := ""

    if (TrimWhitespace == "false" or TrimWhitespace == "0") {
        CoreText := Trim(InputText, " `t`r`n")
        if (CoreText != "") {
            ; Find exact leading and trailing strings by splitting the original text
            LeftP := InStr(InputText, CoreText, true)
            LeadingWS := SubStr(InputText, 1, LeftP - 1)
            TrailingWS := SubStr(InputText, LeftP + StrLen(CoreText))
            ProcessText := CoreText ; Proceed with clean text for the translator
        } else {
            ; Only whitespace selected, proceed as-is (will effectively translate nothing or return original)
            ProcessText := InputText
        }
    } else {
        ProcessText := InputText
    }

    ; Check if Advanced Tokenization is enabled in Settings
    UseTokens := IniRead(SettingsFile, "Settings", "UseTokens", "false")

    ; Temporary file for capturing output
    OutputFile := A_Temp . "\ahk_translate_out.txt"
    ErrorFile := A_Temp . "\ahk_translate_err.txt"

    TotalProviders := Providers.Length
    StartProvider := TranslationSession.CurrentProvider
    Success := false
    AccumulatedErrors := ""

    Loop TotalProviders {
        AttemptIndex := A_Index
        ProviderIndex := Mod(StartProvider - 1 + (AttemptIndex - 1), TotalProviders) + 1
        ProviderName := (ProviderIndex <= ProviderNames.Length) ? ProviderNames[ProviderIndex] : ("Provider " . ProviderIndex)

        ; Prepare text specifically for this provider
        AttemptText := ProcessText
        if (UseTokens == "true" or UseTokens == "1") {
            ; PHASE 1: Collision Protection (Literal Escaping)
            ; Protect any literal occurrences of our tokens in the source text
            ; We remove brackets in the escape version to prevent Phase 3 restoration regex from matching them.
            AttemptText := StrReplace(AttemptText, "[[S]]", "AHK_ESC_S_")
            AttemptText := StrReplace(AttemptText, "[[B]]", "AHK_ESC_B_")
            AttemptText := StrReplace(AttemptText, "[[N]]", "AHK_ESC_N_")

            ; PHASE 2: Functional Tokenization
            ; Tokenize Double Spaces (Indentation) to separate tokens [[S]]
            ; We pad tokens with spaces so DeepL treats them as words, not garbage string
            AttemptText := StrReplace(AttemptText, "  ", " [[S]] ")

            ; DeepL Specific: Tokenize Backslashes to [[B]]
            ; This avoids ANY command line escaping issues or DeepL escape interpretation.
            if (ProviderIndex == 2) {
                AttemptText := StrReplace(AttemptText, "\", " [[B]] ")
            }

            if (PreserveNewlines) {
                ; Use a distinct token which is less likely to be interpreted as grammar
                ; STRICT PRESERVATION: Do NOT pad with spaces.
                Token := "[[N]]"
                AttemptText := StrReplace(AttemptText, "`r`n", Token)
                AttemptText := StrReplace(AttemptText, "`n", Token)
                AttemptText := StrReplace(AttemptText, "`r", Token)
            } else {
                ; Flatten text for CLI (single line)
                AttemptText := StrReplace(AttemptText, "`r`n", " ")
                AttemptText := StrReplace(AttemptText, "`n", " ")
                AttemptText := StrReplace(AttemptText, "`r", " ")
            }
        } else {
            ; Default/Fallback behavior if tokens are disabled
            AttemptText := StrReplace(AttemptText, "`r`n", " ")
            AttemptText := StrReplace(AttemptText, "`n", " ")
            AttemptText := StrReplace(AttemptText, "`r", " ")
        }

        ; Quote escaping is handled by EscapeCmdArg in the command generator

        ; Ensure temp files are clean before execution
        if FileExist(OutputFile)
            FileDelete OutputFile
        if FileExist(ErrorFile)
            FileDelete ErrorFile

        ; Get command for current provider
        ProviderFunc := Providers[ProviderIndex]
        CommandStr := ProviderFunc(AttemptText, SourceLang, TargetLang, OutputFile, ErrorFile)

        if (CommandStr == "") {
            AccumulatedErrors .= "[" . ProviderName . "]: Skipped (command generation failed or API key missing).`n`n"
            continue
        }

        ; Run the command hidden and check for errors
        ExitCode := 0
        try {
            ExitCode := RunWait(CommandStr, , "Hide")
        } catch as err {
            AccumulatedErrors .= "[" . ProviderName . "]: Execution error: " . err.Message . "`n`n"
            if FileExist(OutputFile)
                FileDelete OutputFile
            if FileExist(ErrorFile)
                FileDelete ErrorFile
            continue
        }

        if (ExitCode != 0) {
            ErrorLog := FileExist(ErrorFile) ? Trim(FileRead(ErrorFile, "UTF-8")) : "No error output captured."
            AccumulatedErrors .= "[" . ProviderName . " (Exit Code " . ExitCode . ")]:`n" . ErrorLog . "`n`n"
            if FileExist(OutputFile)
                FileDelete OutputFile
            if FileExist(ErrorFile)
                FileDelete ErrorFile
            continue
        }

        if !FileExist(OutputFile) {
            AccumulatedErrors .= "[" . ProviderName . "]: Output file not created.`n`n"
            if FileExist(ErrorFile)
                FileDelete ErrorFile
            continue
        }

        ; Read the output
        RawOutput := ""
        try {
            RawOutput := FileRead(OutputFile, "UTF-8")
        } catch as err {
            AccumulatedErrors .= "[" . ProviderName . "]: Error reading output file: " . err.Message . "`n`n"
            if FileExist(OutputFile)
                FileDelete OutputFile
            if FileExist(ErrorFile)
                FileDelete ErrorFile
            continue
        }

        if (Trim(RawOutput, " `t`r`n") == "") {
            AccumulatedErrors .= "[" . ProviderName . "]: Empty translation returned.`n`n"
            if FileExist(OutputFile)
                FileDelete OutputFile
            if FileExist(ErrorFile)
                FileDelete ErrorFile
            continue
        }

        ; Process successful output
        TranslatedText := RawOutput

        ; Handle restoration of external whitespace if trimming is disabled
        if (TrimWhitespace == "false" or TrimWhitespace == "0") {
            TranslatedText := LeadingWS . TranslatedText . TrailingWS
        } else if (TrimWhitespace == "true" or TrimWhitespace == "1") {
            TranslatedText := Trim(TranslatedText, " `t`r`n")
        }

        if (UseTokens == "true" or UseTokens == "1") {
            ; DeepL Specific Restore: [[B]] -> \
            ; We use \s* here because these are explicitly padded by us
            if (ProviderIndex == 2) {
                TranslatedText := RegExReplace(TranslatedText, "i)\s*\[\[\s*B\s*\]\]\s*", "\")
            }

            ; Global Restore: [[S]] -> "  " (Double Space)
            ; We use \s* here because these are explicitly padded by us
            TranslatedText := RegExReplace(TranslatedText, "i)\s*\[\[\s*S\s*\]\]\s*", "  ")

            if (PreserveNewlines) {
                ; Remove newlines completely to avoid any spacing artifacts
                TranslatedText := StrReplace(TranslatedText, "`r`n", "")
                TranslatedText := StrReplace(TranslatedText, "`n", "")
                TranslatedText := StrReplace(TranslatedText, "`r", "")

                ; Restore newlines from the token
                TranslatedText := RegExReplace(TranslatedText, "i)\[\[\s*N\s*\]\]", "`n")
            }

            ; PHASE 3: Unescaping Literals
            TranslatedText := RegExReplace(TranslatedText, "i)AHK_ESC_S_", "[[S]]")
            TranslatedText := RegExReplace(TranslatedText, "i)AHK_ESC_B_", "[[B]]")
            TranslatedText := RegExReplace(TranslatedText, "i)AHK_ESC_N_", "[[N]]")
        }

        if (TranslatedText != "") {
            ; Place result in clipboard and paste
            A_Clipboard := TranslatedText
            SendInput "^v"

            ; Restore original text to clipboard so user can use it
            Sleep 200
            A_Clipboard := TranslationSession.SourceText
        }

        ; Cleanup
        if FileExist(OutputFile)
            FileDelete OutputFile
        if FileExist(ErrorFile)
            FileDelete ErrorFile

        Success := true
        break
    }

    if (!Success) {
        if FileExist(OutputFile)
            FileDelete OutputFile
        if FileExist(ErrorFile)
            FileDelete ErrorFile

        MsgBox "Translation failed across all providers:`n`n" . Trim(AccumulatedErrors)
    }
}
