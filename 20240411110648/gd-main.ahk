; AHK v2 syntax

^!+1::
{
    SendInput("^c")
    ClipWait(1)
    Sleep(100)

    main_gd_id := 0
    for id in WinGetList("ahk_exe goldendict.exe")
    {
        WinGetPos(,, &width,, id)
        if (width > 800)
        {
            main_gd_id := id
            break
        }
    }

    if (main_gd_id && WinGetID("A") == main_gd_id)
    {
        ; Case 1: The main window is found and already active. Do nothing.
    }
    else if (main_gd_id)
    {
        ; Case 2: The main window exists but is not active. Activate it.
        WinActivate(main_gd_id)
        WinWaitActive(main_gd_id,, 2)
    }
    else
    {
        ; Case 3: The main window does not exist (app is in tray).
        ; Send the global hotkey to make it appear.
        SendInput("^m")
        WinWait("ahk_exe goldendict.exe",, 2)
        WinActivate()
        ; Sleep(100)
    }

    SendInput("!d") 

    RunWait('C:\Python\Python312\python.exe "C:\Tools\remove_newline_util\remove_newline_util.py"', '', 'Hide')
    Sleep(100)

    SendInput("^v")
    Sleep(100)

    SendInput("{Enter}")
}