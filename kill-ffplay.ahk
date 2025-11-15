; AutoHotkey v2 script to terminate ffplay.exe processes with Ctrl+Alt+O
; Author: Your Name
; Date: 2023-10-01

; Define the hotkey combination: Ctrl (^) + Alt (!) + O
^!+0::
{
    ; Close all instances of ffplay.exe using ProcessClose
    ProcessClose("ffplay.exe")
    
    ; Optional: Uncomment below to show confirmation message Tool ToolTip("ffplay.exe processes terminated", A_ScreenWidth//2, A_ScreenHeight//2)
    ; Sleep(1000)
    ; ToolTip()
}

/*
Explanation:
1. ^!o:: defines the hotkey combination Ctrl+Alt+O
2. ProcessClose() terminates all processes with matching name
3. ToolTip() commands are disabled but show how to add visual feedback
4. Works with both GUI and console versions of ffplay.exe
5. Requires AutoHotkey v2.0+ to run
*/