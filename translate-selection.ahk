#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Google Translate Selection
; Description:  Copies selected text, translates it using a local Python script
;               and replaces the selection with the translation.
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
DeepLKeyFile := A_ScriptDir . "/secrets.ini"
PythonPath := "C:/Tools/deep-translator/venv/Scripts/python.exe"
ScriptPath_Google := "C:/Tools/deep-translator/translate.py"
ScriptPath_DeepL := "C:/Tools/deep-translator/translate.1.py"

GetGoogleCommand(text, src, tgt, outFile) {
    return A_ComSpec ' /c chcp 65001 > nul && "' . PythonPath . '" "' . ScriptPath_Google . '" --text "' . text .
        '" --source ' . src . ' --target ' . tgt . ' > "' . outFile . '"'
}

GetDeepLCommand(text, src, tgt, outFile) {
    apiKey := IniRead(DeepLKeyFile, "DeepL", "Key", "")
    if (apiKey == "") {
        MsgBox "DeepL API Key not found in " . DeepLKeyFile . "`nPlease create it with:`n[DeepL]`nKey=YOUR_KEY"
        return ""
    }
    return A_ComSpec ' /c chcp 65001 > nul && "' . PythonPath . '" "' . ScriptPath_DeepL . '" --text "' . text .
        '" --source ' . src . ' --target ' . tgt . ' --deepl-api-key "' . apiKey . '" > "' . outFile . '"'
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

    if (PreserveNewlines) {
        ; Use a numeric token which is less likely to be interpreted as grammar
        Token := " [[999]] "
        ProcessText := StrReplace(ProcessText, "`r`n", Token)
        ProcessText := StrReplace(ProcessText, "`n", Token)
        ProcessText := StrReplace(ProcessText, "`r", Token)
    } else {
        ; Flatten text for CLI (single line)
        ProcessText := StrReplace(ProcessText, "`r`n", " ")
        ProcessText := StrReplace(ProcessText, "`n", " ")
        ProcessText := StrReplace(ProcessText, "`r", " ")
    }

    ; Escape double quotes for the command line ( " -> \" )
    ProcessText := StrReplace(ProcessText, '"', '\"')

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

            if (PreserveNewlines) {
                ; Remove newlines completely to avoid any spacing artifacts
                TranslatedText := StrReplace(TranslatedText, "`r`n", "")
                TranslatedText := StrReplace(TranslatedText, "`n", "")
                TranslatedText := StrReplace(TranslatedText, "`r", "")

                ; Restore newlines from the numeric token
                ; We look for [[999]] surrounded by optional whitespace
                TranslatedText := RegExReplace(TranslatedText, "\s*\[\[999\]\]\s*", "`n")
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
