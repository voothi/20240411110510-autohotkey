#Requires AutoHotkey v2.0

; ==============================================================================
; Test:         Failover & Provider Cycling Logic (test_failover.ahk)
; Description:  Verifies automated failover loop and manual hotkey cycling.
; ==============================================================================

TotalTests := 0
PassedTests := 0
Failures := ""

; Mock translation session
class MockSession {
    static SourceText := ""
    static CurrentProvider := 1
    static LastHotkey := ""
    static Active := false

    static Reset() {
        this.SourceText := ""
        this.CurrentProvider := 1
        this.LastHotkey := ""
        this.Active := false
    }
}

; Mock runner that simulates provider execution loop
SimulateFailover(CurrentHotkey, InputText, MockProviderBehaviors) {
    ; Check if cycling
    if (MockSession.Active
        && CurrentHotkey == MockSession.LastHotkey
        && InputText == MockSession.SourceText) {

        MockSession.CurrentProvider += 1
        if (MockSession.CurrentProvider > MockProviderBehaviors.Length)
            MockSession.CurrentProvider := 1
    } else {
        MockSession.Reset()
        MockSession.Active := true
        MockSession.LastHotkey := CurrentHotkey
        MockSession.CurrentProvider := 1
        MockSession.SourceText := InputText
    }

    TotalProviders := MockProviderBehaviors.Length
    StartProvider := MockSession.CurrentProvider
    Success := false
    ResultText := ""
    AccumulatedErrors := ""

    loop TotalProviders {
        AttemptIndex := A_Index
        ProviderIndex := Mod(StartProvider - 1 + (AttemptIndex - 1), TotalProviders) + 1
        Behavior := MockProviderBehaviors[ProviderIndex]

        ; Behavior is an object: { exitCode: 0/1, output: "text", err: "msg", skip: false }
        if (Behavior.HasOwnProp("skip") && Behavior.skip) {
            AccumulatedErrors .= "[Provider " . ProviderIndex . "]: Skipped`n"
            continue
        }

        if (Behavior.exitCode != 0) {
            AccumulatedErrors .= "[Provider " . ProviderIndex . "]: Error " . Behavior.err . "`n"
            continue
        }

        if (Trim(Behavior.output, " `t`r`n") == "") {
            AccumulatedErrors .= "[Provider " . ProviderIndex . "]: Empty output`n"
            continue
        }

        ; Succeeded
        ResultText := Behavior.output
        Success := true
        break
    }

    return { success: Success, result: ResultText, errors: Trim(AccumulatedErrors), usedProvider: MockSession.CurrentProvider }
}

AssertEqual(TestName, Actual, Expected) {
    global TotalTests, PassedTests, Failures
    TotalTests++
    if (Actual == Expected) {
        PassedTests++
    } else {
        Failures .= "`n- " . TestName . ":`n  Expected: [" . Expected . "]`n  Actual:   [" . Actual . "]"
    }
}

; --- TEST CASES ---

; 1. Primary provider succeeds directly
MockBehaviors1 := [{ exitCode: 0, output: "Google result", err: "" }, { exitCode: 0, output: "DeepL result", err: "" }]
res1 := SimulateFailover("^!F2", "hello", MockBehaviors1)
AssertEqual("Primary success", res1.success, true)
AssertEqual("Primary output", res1.result, "Google result")

; 2. Primary fails (rate limit / 500), secondary succeeds (Failover)
MockBehaviors2 := [{ exitCode: 1, output: "", err: "HTTP 429 Too Many Requests" }, { exitCode: 0, output: "DeepL fallback result",
    err: "" }]
res2 := SimulateFailover("^!F2", "hello", MockBehaviors2)
AssertEqual("Failover success", res2.success, true)
AssertEqual("Failover output", res2.result, "DeepL fallback result")

; 3. All providers fail -> aggregated errors
MockBehaviors3 := [{ exitCode: 1, output: "", err: "HTTP 500 Internal Server Error" }, { exitCode: 1, output: "", err: "DeepL API quota exceeded" }]
res3 := SimulateFailover("^!F2", "hello", MockBehaviors3)
AssertEqual("All fail -> success is false", res3.success, false)
AssertEqual("Aggregated errors collected", InStr(res3.errors, "HTTP 500") > 0 && InStr(res3.errors, "quota exceeded") >
0, true)

; 4. Manual Hotkey Cycling
; First press: Provider 1 active
MockSession.Reset()
c1 := SimulateFailover("^!F2", "word", MockBehaviors1)
AssertEqual("Cycling 1st press provider", MockSession.CurrentProvider, 1)

; Second press (same hotkey, same text): Cycles to Provider 2
c2 := SimulateFailover("^!F2", "word", MockBehaviors1)
AssertEqual("Cycling 2nd press provider", MockSession.CurrentProvider, 2)
AssertEqual("Cycling 2nd press output", c2.result, "DeepL result")

; Third press: Wraps around to Provider 1
c3 := SimulateFailover("^!F2", "word", MockBehaviors1)
AssertEqual("Cycling 3rd press wraps to 1", MockSession.CurrentProvider, 1)

; New text reset: resets to Provider 1
c4 := SimulateFailover("^!F2", "different word", MockBehaviors1)
AssertEqual("New text resets provider", MockSession.CurrentProvider, 1)

; 5. Error Log Formatting & JSON / Unicode decoding
FormatErrorLog(rawLog) {
    if (rawLog == "")
        return "No error output captured."

    if RegExMatch(rawLog, 's)"message"\s*:\s*"((?:[^"\\]|\\.)*)"', &match) {
        msg := match[1]
        msg := StrReplace(msg, '\"', '"')
        msg := StrReplace(msg, '\n', "`n")
        msg := StrReplace(msg, '\r', "")
        msg := StrReplace(msg, '\t', "`t")
        msg := StrReplace(msg, '\\', '\')

        pos := 1
        while RegExMatch(msg, '\\u([0-9a-fA-F]{4})', &uMatch, pos) {
            codePoint := Integer("0x" . uMatch[1])
            char := Chr(codePoint)
            msg := StrReplace(msg, uMatch[0], char, false, 1)
            pos := InStr(msg, char) + 1
        }
        return msg
    }

    cleanLog := rawLog
    pos := 1
    while RegExMatch(cleanLog, '\\u([0-9a-fA-F]{4})', &uMatch, pos) {
        codePoint := Integer("0x" . uMatch[1])
        char := Chr(codePoint)
        cleanLog := StrReplace(cleanLog, uMatch[0], char, false, 1)
        pos := InStr(cleanLog, char) + 1
    }
    return cleanLog
}

sampleJson := 'Attempt 1 failed: TransientResponseError. Retrying in 2.70s...`n{"status": "error", "message": "Google translation failed: \u0414\u043e\u0431\u0430\u0432\u044c --> No translation found."}'
formattedErr := FormatErrorLog(sampleJson)
AssertEqual("FormatErrorLog decodes Unicode Cyrillic", InStr(formattedErr, "Добавь") > 0, true)
AssertEqual("FormatErrorLog extracts clean message", InStr(formattedErr, "Attempt 1 failed") == 0, true)

; --- REPORT ---
ResultMsg := "Test Results: " . PassedTests . "/" . TotalTests . " Passed"
if (Failures != "") {
    MsgBox ResultMsg . "`n`nFailures:" . Failures, "Failover Test - FAILED", "Icon!"
} else {
    FileAppend ResultMsg . "`nAll failover integration tests passed.`n", A_Temp . "\ahk_test_failover_out.txt"
}
