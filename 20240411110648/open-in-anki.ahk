#Requires AutoHotkey v2.0

pythonPath := "C:\Python\Python312\python.exe"
scriptPath := "C:\Tools\anki-search\anki-search.py"

#HotIf WinActive("ahk_exe goldendict.exe")

^!a::
{
    A_Clipboard := ""
    SendInput("^c")
    
    if !ClipWait(1)
        Return

    local command := '"' . pythonPath . '" "' . scriptPath . '" --browse-clipboard'
    Run(command,, "Hide")

    if WinWait("Browse ahk_exe anki.exe",, 2)
    {
        WinActivate("Browse ahk_exe anki.exe")
    }
}

#HotIf