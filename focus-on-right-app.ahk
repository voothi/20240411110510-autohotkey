^!h:: {
    ; If WinActive("ahk_exe goldendict.exe") {
        ; Step 3: Delay before sending the key combination (e.g., 500 milliseconds)
        ; Sleep(500)

        ; Step 4: Get the current mouse position
        MouseGetPos(&xpos, &ypos)

        ; Step 5: Move the mouse pointer 1024 pixels to the right
        MouseMove(xpos + 1417, ypos, 0)

        ; Step 6: Return the pointer to the original position
        ; MouseMove(xpos, ypos, 0)
    ; }
}