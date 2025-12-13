#Requires AutoHotkey v2.0

TestString := 'path = "C:\"'
Result := EscapeCmdArg(TestString)

FileAppend("Original: " . TestString . "`n", "debug_output.txt")
FileAppend("Escaped:  " . Result . "`n", "debug_output.txt")

MsgBox("Original: " . TestString . "`nEscaped: " . Result)

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
