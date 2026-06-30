#Requires AutoHotkey v2.0
#Include "..\Lib\B64Util.ahk"

; Minimal Mock setup for kardenwort-window behaviors
global G_WindowCount := 0

GetCascadeCoords(&x, &y) {
    global G_WindowCount
    x := 50 + G_WindowCount * 30
    y := 50 + G_WindowCount * 30
    G_WindowCount := Mod(G_WindowCount + 1, 15)
}

; Test 1: Base64 Encoding & Decoding compatibility
text := "Hello World! This is Kardenwort GUI testing. 🇩🇪"
encoded := B64Encode(text)
decoded := B64Decode(encoded)

if (decoded == text) {
    FileAppend("SUCCESS: Base64 encoding/decoding matched original text.`n", "test_results.txt")
} else {
    FileAppend("FAILURE: Base64 mismatch!`nExpected: " text "`nGot: " decoded "`n", "test_results.txt")
}

; Test 2: Cascade layout coords offset calculation
G_WindowCount := 0
GetCascadeCoords(&x1, &y1)
GetCascadeCoords(&x2, &y2)
GetCascadeCoords(&x3, &y3)

if (x1 == 50 && y1 == 50 && x2 == 80 && y2 == 80 && x3 == 110 && y3 == 110) {
    FileAppend("SUCCESS: Cascading coordinates incremented correctly.`n", "test_results.txt")
} else {
    FileAppend("FAILURE: Cascading coordinates calculation error.`nGot (x1,y1): (" x1 "," y1 ") (x2,y2): (" x2 "," y2 ")`n", "test_results.txt")
}

; Test 3: Cascade wrap-around behavior
G_WindowCount := 14
GetCascadeCoords(&x14, &y14)
GetCascadeCoords(&x15, &y15) ; should wrap to 0 (50, 50)

if (x14 == 470 && x15 == 50) {
    FileAppend("SUCCESS: Coordinate wrap-around reset after 15 windows.`n", "test_results.txt")
} else {
    FileAppend("FAILURE: Coordinate wrap-around failed. x14=" x14 " x15=" x15 "`n", "test_results.txt")
}

; Test 4: Verify config file existence and format
configPath := "..\kardenwort-window\config.ini"
if FileExist(configPath) {
    pythonPath := IniRead(configPath, "Paths", "DeskPythonPath", "")
    scriptPath := IniRead(configPath, "Paths", "DeskScriptPath", "")
    if (pythonPath != "" && scriptPath != "") {
        FileAppend("SUCCESS: Config paths read correctly.`n", "test_results.txt")
    } else {
        FileAppend("FAILURE: Config paths are empty.`n", "test_results.txt")
    }
} else {
    FileAppend("FAILURE: Config file not found at " configPath "`n", "test_results.txt")
}
