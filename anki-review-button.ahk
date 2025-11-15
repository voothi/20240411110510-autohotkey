^!r:: {
    If WinActive("ahk_exe anki.exe") {
        ; Step 1: Delay before sending the key combination (e.g., 500 milliseconds)
        Sleep(500)

        ; Step 2: Simulate pressing the key combination Ctrl + Shift + P
        ; Send("^!{p}")
        Send("^+p")

        ; Step 3: Delay before sending the key combination (e.g., 500 milliseconds)
        Sleep(500)

        ; Step 4: Get the current mouse position
        MouseGetPos(&xpos, &ypos)

        ; Step 5: Move the mouse pointer 1024 pixels to the right
        MouseMove(xpos + 1024, ypos, 0)

        ; Step 6: Return the pointer to the original position
        MouseMove(xpos, ypos, 0)
    }
}