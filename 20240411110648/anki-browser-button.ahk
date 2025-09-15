^!+]:: {
    If WinActive("ahk_exe anki.exe") {
        Click()
        Sleep(150)
        Send("^a")
        Sleep(150)
        Send("^j")
        Sleep(150)
        Click()
    }
}