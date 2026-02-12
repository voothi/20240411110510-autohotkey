#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Setup Test Environment ---
global logFile := A_ScriptDir "\test_merged.log"
try FileDelete(logFile)

LogResult(msg) {
    FileAppend(A_Now ": " msg "`n", logFile)
    OutputDebug("TTS_TEST: " msg "`n")
}

Assert(condition, message) {
    if !condition {
        LogResult("FAIL: " message)
        MsgBox("FAIL: " message)
        ExitApp(1)
    } else {
        LogResult("PASS: " message)
    }
}

; --- Prepare Test Config ---
testConfig := A_ScriptDir "\test_config.ini"
if FileExist(testConfig)
    FileDelete(testConfig)

configContent :=
    (
        "[Paths]
PythonPath=test_python.exe
ScriptPath=test_script.py

[Settings]
DefaultLanguage=en
DoublePressDelay=500

[Languages]
en=En,0x0,0xF,^!+2
de=De,0x0,0xF,^!+3
ru=Ru,0x0,0xF,^!+4"
    )
FileAppend(configContent, testConfig)

; --- Include Script Under Test ---
#Include "../tts.ahk"

; --- Mocking via Delegates ---
global lastRunCommand := ""
MockRun(Target, WorkingDir := "", Options := "", &OutputVarPID := "") {
    global lastRunCommand := Target
    LogResult("MockRun called with: " Target)
}

; Override the delegate in tts.ahk
global RunExternal := MockRun

; Point to test config
global configFile := testConfig

MsgBox("Starting Merged Test Suite...")

; --- PHASE 1: Unit Tests (Initialization & Logic) ---
LogResult("--- Starting Unit Tests ---")

InitializeTTS()

Assert(currentLang == "en", "Initial language should be en")
Assert(langCodes.Length == 3, "Should have loaded 3 languages")
Assert(pythonPath == "test_python.exe", "Should have loaded python path from test config")

; Test CycleLanguage Logic
CycleLanguage()
Assert(currentLang == "de", "Cycle: en -> de")

CycleLanguage()
Assert(currentLang == "ru", "Cycle: de -> ru")

CycleLanguage()
Assert(currentLang == "en", "Cycle: ru -> en (wrap)")

; --- PHASE 2: Integration / Behavior Tests ---
LogResult("--- Starting Integration Tests ---")

SetLanguage("de")
Assert(currentLang == "de", "SetLanguage('de') works")

; Verify RunPythonScript forms the correct command
A_Clipboard := "Hello World"
RunPythonScript()
Sleep(100)
expectedCmd := '"test_python.exe" "test_script.py" "Hello World" "de"'
Assert(InStr(lastRunCommand, expectedCmd), "RunPythonScript executing correct command. Got: " lastRunCommand)

MsgBox("Merged Tests Completed.`n`nCheck " logFile " for details.")
FileDelete(testConfig)
ExitApp(0)