$<^c::
{
    A_Clipboard := ""
    Send("{LControl Down}c{LControl Up}")

    if !ClipWait(0.5)
    {
        KeyWait("LCtrl")
        return
    }

    Sleep(80)
    Send("{LControl Down}c{LControl Up}")
    
    KeyWait("LCtrl")
}