^!+q::
{
    ; A_Clipboard := ""
    ; SendInput("{LControl Down}c{LControl Up}")
    SendInput("^c")
    RunWait('C:\Python\Python312\python.exe "C:\Tools\remove_newline_util\remove_newline_util.py"', '', 'Hide')

    if ClipWait(1)
    {
        ; Sleep(100)
        ; SendInput("{LControl Down}c{LControl Up}")
        SendInput("^c")
    }
}