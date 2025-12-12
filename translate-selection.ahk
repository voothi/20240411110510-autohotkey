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

; ===================================================================================
; CONFIGURATION
;Path to the Python interpreter (e.g. from a virtual environment)
global PythonPath := "C:/Tools/deep-translator/venv/Scripts/python.exe"

; Path to the Python translation script
global ScriptPath := "C:/Tools/deep-translator/translate.py"
; ===================================================================================

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
        return
    }

    ; Get text
    InputText := A_Clipboard

    ; Flatten text to single line
    InputText := StrReplace(InputText, "`r`n", " ")
    InputText := StrReplace(InputText, "`n", " ")
    InputText := StrReplace(InputText, "`r", " ")

    ; Escape double quotes for the command line ( " -> \" )
    InputText := StrReplace(InputText, '"', '\"')

    ; Temporary file for capturing output
    OutputFile := A_Temp . "\ahk_translate_out.txt"
    if FileExist(OutputFile)
        FileDelete OutputFile

    ; Construct the command line.
    ; Uses global PythonPath and ScriptPath defined in the header
    CommandStr := A_ComSpec ' /c chcp 65001 > nul && "' . PythonPath . '" "' . ScriptPath . '" --text "' . InputText .
        '" --source ' . SourceLang . ' --target ' . TargetLang . ' > "' . OutputFile . '"'

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

                ; Send Paste
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
