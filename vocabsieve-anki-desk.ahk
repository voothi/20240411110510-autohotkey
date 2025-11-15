; #Persistent

; Ctrl + Alt + O
^!sc018:: {
    ; Check if the window app.exe is active
    if WinActive("ahk_exe app.exe") || WinActive("ahk_exe app_win32.exe") {
        Sleep(200) ; Pause for 200 ms
        
        ; Press Alt
        ; Send("{Alt}")
        ; Sleep(200) ; Pause for 200 ms
        
        ; ; Press Right Arrow
        ; Send("{Right}")
        ; Sleep(200) ; Pause for 200 ms

        ; Press Ctrl+C
        Send("!{c}")
        Sleep(200) ; Pause for 200 ms
        
        ; Press Enter
        Send("{Enter}")
        Sleep(200) ; Pause for 200 ms
        
        ; Press Enter again
        ; Send("{Enter}")
        ; Sleep(200) ; Pause for 200 ms
        
        ; Wait for the window to open
        ; Sleep(200) ; Pause for 200 ms
        
        ; Press Right Arrow
        Send("{Right}")
        Sleep(200) ; Pause for 200 ms
        
        ; Press Right Arrow
        Send("{Right}")
        Sleep(200) ; Pause for 200 ms
        
        ; Press Right Arrow
        Send("{Right}")
        Sleep(200) ; Pause for 200 ms
        
        ; Press Tab
        Send("{Tab}")
        Sleep(200) ; Pause for 200 ms
        
        ; Press Tab
        Send("{Tab}")
        Sleep(200) ; Pause for 200 ms
        
        ; Press Tab
        Send("{Tab}")
        Sleep(200) ; Pause for 200 ms
        
        ; Press Alt + Down Arrow
        Send("!{Down}")
        Sleep(200) ; Pause for 200 ms
    }
}