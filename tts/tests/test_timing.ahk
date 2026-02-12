#Requires AutoHotkey v2.0

; Mock globals to simulate tts.ahk behavior
global currentLang := "en"
global doublePressDelay := 500
global langCodes := ["en", "de", "ru", "uk"]
global logFile := A_ScriptDir "\test_result.log"

if FileExist(logFile)
    FileDelete(logFile)

LogAction(msg) {
    FileAppend(A_Now ": " msg "`n", logFile)
    ToolTip(msg)
    SetTimer(() => ToolTip(), -2000)
}

CycleLanguage() {
    global currentLang, langCodes
    currentIndex := 0
    for i, code in langCodes {
        if (code = currentLang) {
            currentIndex := i
            break
        }
    }
    nextIndex := currentIndex + 1
    if (nextIndex > langCodes.Length)
        nextIndex := 1
    currentLang := langCodes[nextIndex]
    LogAction("Switched to: " currentLang)
}

RunPythonScript(*) {
    LogAction("TRIGGERED PLAYBACK (Lang: " currentLang ")")
}

; HOTKEY UNDER TEST
~LButton & MButton:: {
    if (A_PriorHotkey == "~LButton & MButton" && A_TimeSincePriorHotkey < doublePressDelay) {
        SetTimer(RunPythonScript, 0) ; Cancel pending playback
        CycleLanguage()
    } else {
        SetTimer(RunPythonScript, -doublePressDelay)
    }
}

Esc:: ExitApp()

MsgBox "Test script running.`n`n1. Hold Left Click.`n2. Click Middle once -> Wait 0.5s -> Should trigger PLAYBACK.`n3. Click Middle twice FAST -> Should trigger CYCLE.`n`nPress ESC to exit."