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
    ; Check if we are cycling (same hotkey pressed again)
    isCycling := (TranslationSession.Active && A_ThisHotkey == TranslationSession.LastHotkey)

    if (isCycling) {
        ; Cycle to next provider
        TranslationSession.CurrentProvider += 1
        if (TranslationSession.CurrentProvider > Providers.Length)
            TranslationSession.CurrentProvider := 1

        ; Undo previous translation (Simulate Ctrl+Z)
        SendInput "^z"
        Sleep 200 ; Wait for undo to complete

        ; Use original text from session
        InputText := TranslationSession.SourceText
    } else {
        ; Start New Session
        TranslationSession.Reset()
        TranslationSession.Active := true
        TranslationSession.LastHotkey := A_ThisHotkey
        TranslationSession.CurrentProvider := 1

        ; Clear clipboard for ClipWait detection
        A_Clipboard := ""

        ; Copy selected text
        SendInput "^c"
        if !ClipWait(1) {
            MsgBox "No text selected or copy failed."
            TranslationSession.Reset()
            return
        }

        ; Store original text
        InputText := A_Clipboard
        TranslationSession.SourceText := InputText
    }

    ; Flatten text for CLI (as per current logic)
    ProcessText := StrReplace(InputText, "`r`n", " ")
    ProcessText := StrReplace(ProcessText, "`n", " ")
    ProcessText := StrReplace(ProcessText, "`r", " ")

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

            if (TranslatedText != "") {
                ; Place result in clipboard and paste
                A_Clipboard := TranslatedText
                SendInput "^v"
            }
        }
        catch as err {
            MsgBox "Error reading output file: " . err.Message
        }

        ; Cleanup
        FileDelete OutputFile
    }
}
