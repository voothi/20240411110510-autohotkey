^!+]:: {
    If WinActive("ahk_exe anki.exe") {
        Click()
        Sleep(150)
        Send("^a")
        Sleep(150)
        Send("^j")
        Sleep(300)
        Click()
        Sleep(150)
        Send("^!r")
    }
}