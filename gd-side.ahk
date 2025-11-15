^!+q::
{
    ; A_Clipboard := ""
    ; SendInput("{LControl Down}c{LControl Up}")
    SendInput("^c")

    if ClipWait(1)
    {
        RunWait('C:\Python\Python312\python.exe "C:\Tools\remove_newline_util\remove_newline_util.py"', '', 'Hide')
    }
    ; Sleep(100)
    SendInput("^!+n")

    ; if ClipWait(1)
    ; {
    ;     ; Sleep(100)
    ;     ; SendInput("{LControl Down}c{LControl Up}")
    ;     ; SendInput("^c")
    ; }
}