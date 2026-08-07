#Requires AutoHotkey v2.0

if (A_Args.Length < 1) {
    FileAppend("ERROR: Expected window count argument.`n", "*")
    ExitApp(1)
}

expectedCount := Integer(A_Args[1])
timeoutSecs := 30
if (A_Args.Length >= 2) {
    timeoutSecs := Integer(A_Args[2])
}

startTime := A_TickCount
SetTitleMatchMode(2) ; 2: A window's title can contain WinTitle anywhere inside it to be a match.

Loop {
    ids := WinGetList("Kardenwort - ")
    count := ids.Length
    
    if (count == expectedCount) {
        FileAppend("SUCCESS: Found " count " Kardenwort windows.`n", "*")
        ExitApp(0)
    }
    
    if ((A_TickCount - startTime) > (timeoutSecs * 1000)) {
        FileAppend("TIMEOUT: Expected " expectedCount " windows, but found " count " after " timeoutSecs "s.`n", "*")
        ExitApp(1)
    }
    
    Sleep(250)
}
