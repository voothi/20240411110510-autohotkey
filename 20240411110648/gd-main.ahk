; AHK v2 syntax

^!+1::
{
    Send("^c")
    ClipWait(1)
    Sleep(100)

    active_id := WinGetID("A")
    main_gd_id := 0
    gd_windows := WinGetList("ahk_exe goldendict.exe")

    for id in gd_windows
    {
        WinGetPos(,, &width,, id)
        if (width > 800)
        {
            main_gd_id := id
            break
        }
    }

    if main_gd_id
    {
        if (active_id != main_gd_id)
        {
            WinActivate(main_gd_id)
            WinWaitActive(main_gd_id,, 2)
            Send("^m")
            Sleep(100)
        }
    }
    else
    {
        WinActivate("ahk_exe goldendict.exe")
        WinWaitActive("ahk_exe goldendict.exe",, 2)
        Send("^m")
        Sleep(100)
    }

    RunWait('C:\Python\Python312\python.exe "C:\Tools\remove_newline_util\remove_newline_util.py"', '', 'Hide')
    Sleep(750)

    Send("^v")
    Sleep(100)

    Send("{Enter}")
}