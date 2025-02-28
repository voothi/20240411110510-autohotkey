^!+1::
{
    Send("^c")
    ClipWait(1) ; Wait until the clipboard contains data
    Sleep(250) ; Wait for 100 ms

    ; Check if the current active window is goldendict.exe and the window title contains "GoldenDict-ng"
    if WinActive("ahk_exe goldendict.exe") && InStr(WinGetTitle("A"), "GoldenDict-ng") {
        ; Send the shortcut twice
        Send("^!+w")
        Sleep(100) ; Wait for 100 ms
        Send("^!+w")
        Sleep(100) ; Wait for 100 ms
    } else {
        ; If it's not goldendict, send the shortcut once
        Send("^!+w")
        Sleep(100) ; Wait for 100 ms
    }

    Send("^v")
    Sleep(100) ; Wait for 100 ms
    Send("{Enter}")
}