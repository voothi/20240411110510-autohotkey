^!+1::
{
    Send("^c")
    ClipWait(1) ; Wait until the clipboard contains data
    Sleep(100) ; Wait for 100 ms

    ; Check if the current active window is goldendict.exe and the window title contains "GoldenDict-ng"
    if WinActive("ahk_exe goldendict.exe") && InStr(WinGetTitle("A"), "GoldenDict-ng") {
        ; Send the shortcut twice
        
        ; 20250513085430 New version of GD
        ; Send("^!+w")
        ; Sleep(100) ; Wait for 100 ms

        Send("^m")
        Sleep(100) ; Wait for 100 ms
    } else {
        ; If it's not goldendict, send the shortcut once
        Send("^m")
        Sleep(100) ; Wait for 100 ms
    }

    ; Default option. As in the original, with line breaks.
    ; Send("^v")
    ; Sleep(100) ; Wait for 100 ms

    ; Variant with removal of line breaks. After processing.
    RunWait("C:\Python\Python312\python.exe C:\Tools\remove_newline_util\remove_newline_util.py", "", "Hide")
    Sleep(750)

    Send("^v")
    Sleep(100) ; Wait for 100 ms

    ; Common code for both options. Sending data from the field.
    Send("{Enter}")
}