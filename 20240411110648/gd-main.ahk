; AHK v2 syntax

^!+1::
{
    Send("^c")
    ClipWait(1)
    Sleep(100)

    main_gd_id := 0
    gd_windows := WinGetList("ahk_exe goldendict.exe")

    for id in gd_windows
    {
        WinGetPos(,, &width,, id)
        if (width > 400)
        {
            main_gd_id := id
            break
        }
    }

    if main_gd_id
    {
        WinActivate(main_gd_id)
        WinWaitActive(main_gd_id,, 2)
    }
    else
    {
        WinActivate("ahk_exe goldendict.exe")
    }

    Send("^m")
    Sleep(100)

    RunWait('C:\Python\Python312\python.exe "C:\Tools\remove_newline_util\remove_newline_util.py"', '', 'Hide')
    Sleep(750)

    Send("^v")
    Sleep(100)

    Send("{Enter}")
}