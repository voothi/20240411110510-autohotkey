#Requires AutoHotkey v2.0

#HotIf WinActive("ahk_exe chrome.exe") and InStr(WinGetTitle("A"), "Google AI Studio")

    Enter::Send "+{Enter}"

    ^Enter::Send "{Enter}"

#HotIf

; Hotkey: Shift + Win + C
+#c::
{
    textToInsert := "
    (
    ```

    ```
    )"
    Send(textToInsert)
    Send("{Up 2}")
}