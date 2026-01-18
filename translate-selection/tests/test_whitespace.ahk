#Requires AutoHotkey v2.0

; ==============================================================================
; Test:         Whitespace Preservation Logic
; Description:  Verifies the extraction and restoration of leading/trailing
;               whitespace for the translation utility.
; ==============================================================================

TotalTests := 0
PassedTests := 0
Failures := ""

; Test Runner
RunTest(Description, InputText, MockTranslatedCore, ExpectedOutput) {
    global TotalTests, PassedTests, Failures
    TotalTests++

    ; --- Logic to test (replicated from translate-selection.ahk) ---
    CoreText := Trim(InputText, " `t`r`n")
    LeadingWS := ""
    TrailingWS := ""

    if (CoreText != "") {
        LeftP := InStr(InputText, CoreText, true)
        LeadingWS := SubStr(InputText, 1, LeftP - 1)
        TrailingWS := SubStr(InputText, LeftP + StrLen(CoreText))
    } else {
        ; Case: Pure whitespace
        ActualOutput := InputText
        goto Finish
    }

    ; Simulate translation of the CoreText
    ActualOutput := LeadingWS . MockTranslatedCore . TrailingWS
    ; ----------------------------------------------------------------

Finish:
    if (ActualOutput == ExpectedOutput) {
        PassedTests++
    } else {
        Failures .= "`n- " . Description . ":`n  Expected: [" . StrReplace(StrReplace(ExpectedOutput, "`r", "\r"), "`n",
        "\n") . "]`n  Actual:   [" . StrReplace(StrReplace(ActualOutput, "`r", "\r"), "`n", "\n") . "]"
    }
}

; --- Test Cases ---

; 1. Accidental space after period (User Requirement)
RunTest("Trailing Space", "пробел. ", "space.", "space. ")

; 2. Leading space
RunTest("Leading Space", " пробел", "space", " space")

; 3. Both sides
RunTest("Both Sides", " text ", "translated", " translated ")

; 4. Newlines
RunTest("Newlines", "`nline`r`n", "line_translated", "`nline_translated`r`n")

; 5. Pure whitespace (ensure no crash)
RunTest("Pure Whitespace", "  ", "", "  ")

; 6. Tabs and mixed
RunTest("Mixed WS", "`t word `n ", "word_translated", "`t word_translated `n ")

; --- Report ---
ResultMsg := "Tests Completed: " . PassedTests . "/" . TotalTests
if (Failures != "") {
    MsgBox ResultMsg . "`n`nFailures:" . Failures, "Whitespace Logic Test - FAILED", "Icon!"
} else {
    MsgBox ResultMsg . "`n`nAll whitespace logic tests passed successfully.", "Whitespace Logic Test - PASSED", "Iconi"
}
