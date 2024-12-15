^!s:: {
    ; Click the left mouse button
    Click()
    
    ; Press Home
    Send("{Home}")
    Sleep(200) ; Pause for 200 ms
    
    ; Press Ctrl+A
    Send("^a")
    Sleep(200) ; Pause for 200 ms
    
    ; Press Ctrl+C
    Send("^c")
    Sleep(200) ; Pause for 200 ms
    
    ; Press Ctrl+S
    Send("^s")
    Sleep(200) ; Pause for 200 ms
    
    ; Press Space
    Send("{Space}")
    
    ; Press Backspace
    Send("{Backspace}")
    Sleep(1000) ; Pause for 1000 ms
    
    ; Paste in the window
    Send("^v")
}