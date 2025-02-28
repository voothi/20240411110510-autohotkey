^!`::
{
    ; Step 1: Copy the selected text to the clipboard
    Send("^c")
    ClipWait(1) ; Wait until the clipboard contains data

    ; Step 2: Press Ctrl + Alt + F12
    Send("^!{F12}")
    Sleep(100) ; Wait for 100 ms

    ; Step 3: Paste the content from the clipboard
    Send("^v")
    Sleep(100) ; Wait for 100 ms

    ; Step 4: Press Enter
    Send("{Enter}")
}