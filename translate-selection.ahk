#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Google Translate Selection
; Hotkey:       Ctrl + Alt + Shift + ` (Backtick/Tilde)
; Description:  Copies selected text, translates it using a local Python script
;               via deep-translator, and replaces the selection with the translation.
; ===================================================================================

^!+sc029::
{
    ; Save the current clipboard content to restore later if needed (optional implementation)
    ; For this specific request, we just use the clipboard for the operation.

    ; Clear clipboard for ClipWait detection
    A_Clipboard := ""

    ; Copy selected text
    SendInput "^c"
    if !ClipWait(1) {
        MsgBox "No text selected or copy failed."
        return
    }

    ; Get text and prepare valid command line argument
    InputText := A_Clipboard

    ; Flatten text to single line to prevent command line errors (simple approach)
    ; Replacing newlines with spaces.
    InputText := StrReplace(InputText, "`r`n", " ")
    InputText := StrReplace(InputText, "`n", " ")
    InputText := StrReplace(InputText, "`r", " ")

    ; Escape double quotes for the command line ( " -> \" )
    InputText := StrReplace(InputText, '"', '\"')

    ; Define paths (using forward slashes as requested)
    PythonPath := "C:/Tools/deep-translator/venv/Scripts/python.exe"
    ScriptPath := "C:/Tools/deep-translator/translate.py"

    ; Temporary file for capturing output
    OutputFile := A_Temp . "\ahk_translate_out.txt"
    if FileExist(OutputFile)
        FileDelete OutputFile

    ; Construct the command line.
    ; We use cmd.exe /c to handle stdout redirection to the temp file.
    ; Note: Standard CMD might require backslashes for the executable path,
    ; but we strictly follow the user's request to use forward slashes.
    ; If this fails, consider changing PythonPath to use backslashes.
    ; We also set output encoding to UTF-8 using chcp 65001.

    CommandStr := A_ComSpec ' /c chcp 65001 > nul && "' . PythonPath . '" "' . ScriptPath . '" --text "' . InputText .
        '" --source ru --target en > "' . OutputFile . '"'

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
