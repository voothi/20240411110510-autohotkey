^!1::
{
    Send("^c")
    ClipWait(1) ; Wait until the clipboard contains data
    Sleep(100) ; Wait for 100 ms

    Send("^!q")
    Sleep(100) ; Wait for 100 ms

    Send("^v")
    Sleep(100) ; Wait for 100 ms

    Send("{Enter}")
}