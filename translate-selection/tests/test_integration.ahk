#Requires AutoHotkey v2.0

; ==============================================================================
; Test:         Full Logic Integration (translate-selection.ahk)
; Description:  Verifies the complete text processing pipeline:
;               1. Whitespace Extraction (Boundary Protection)
;               2. Literal Escaping (Collision Protection)
;               3. Functional Tokenization (Structure Preservation)
;               4. Restoration & Unescaping (Reconstruction)
; ==============================================================================

TotalTests := 0
PassedTests := 0
Failures := ""

SimulateFullLogic(InputText, MockTranslatedCore, UseTokens := true) {
    ; --- 1. WHITESPACE EXTRACTION ---
    CoreText := Trim(InputText, " `t`r`n")
    LeadingWS := ""
    TrailingWS := ""
    if (CoreText != "") {
        LeftP := InStr(InputText, CoreText, true)
        LeadingWS := SubStr(InputText, 1, LeftP - 1)
        TrailingWS := SubStr(InputText, LeftP + StrLen(CoreText))
    } else {
        return InputText ; Pure whitespace
    }

    ; --- 2. PRE-PROCESSING (CoreText) ---
    ProcessText := CoreText
    if (UseTokens) {
        ; Phase 1: Escape literals (Collision Protection)
        ProcessText := StrReplace(ProcessText, "[[S]]", "AHK_ESC_S_")
        ProcessText := StrReplace(ProcessText, "[[B]]", "AHK_ESC_B_")
        ProcessText := StrReplace(ProcessText, "[[N]]", "AHK_ESC_N_")

        ; Phase 2: Tokenize (Functional Structure)
        ; (Mocking the logic that runs before API call)
        ProcessText := StrReplace(ProcessText, "  ", " [[S]] ")
        ProcessText := StrReplace(ProcessText, "`r`n", "[[N]]")
        ProcessText := StrReplace(ProcessText, "`n", "[[N]]")
    }

    ; --- 3. RESTORATION (Post-API Reassembly) ---
    ; MockTranslatedCore is what we assume comes back from API for ProcessText
    Translated := MockTranslatedCore

    ; Re-attach boundary whitespace
    Translated := LeadingWS . Translated . TrailingWS

    if (UseTokens) {
        ; Phase 3: Restore functional tokens
        Translated := RegExReplace(Translated, "i)\s*\[\[\s*S\s*\]\]\s*", "  ")
        Translated := RegExReplace(Translated, "i)\s*\[\[\s*B\s*\]\]\s*", "\")
        Translated := RegExReplace(Translated, "i)\[\[\s*N\s*\]\]", "`n")

        ; Phase 3: Unescape literals
        Translated := RegExReplace(Translated, "i)AHK_ESC_S_", "[[S]]")
        Translated := RegExReplace(Translated, "i)AHK_ESC_B_", "[[B]]")
        Translated := RegExReplace(Translated, "i)AHK_ESC_N_", "[[N]]")
    }

    return Translated
}

RunTest(Description, InputText, MockTranslatedCore, ExpectedOutput, UseTokens := true) {
    global TotalTests, PassedTests, Failures
    TotalTests++

    ActualOutput := SimulateFullLogic(InputText, MockTranslatedCore, UseTokens)

    if (ActualOutput == ExpectedOutput) {
        PassedTests++
    } else {
        Failures .= "`n- " . Description . ":`n  Expected: [" . StrReplace(StrReplace(ExpectedOutput, "`r", "\r"), "`n",
        "\n") . "]`n  Actual:   [" . StrReplace(StrReplace(ActualOutput, "`r", "\r"), "`n", "\n") . "]"
    }
}

; --- TEST SUITE ---

; 1. Boundary Whitespace
RunTest("Boundary: Leading & Trailing", "  word  ", "word", "  word  ", false)
RunTest("Boundary: Newlines", "`nline`n", "line", "`nline`n", false)
RunTest("Boundary: Pure WS", "  `n  ", "ignored", "  `n  ")

; 2. Functional Tokenization (Unit logic)
RunTest("Token: Indentation", "  code", "[[S]] code", "  code")
RunTest("Token: Newline Strictness", "`n", "[[N]]", "`n")
RunTest("Token: DeepL Backslash", "\", "[[B]]", "\")

; 3. Collision Protection (The "Wikilink" Bug)
RunTest("Collision: Literal [[S]]", "[[S]]", "AHK_ESC_S_", "[[S]]")
RunTest("Collision: Literal [[N]]", "See [[N]]", "See AHK_ESC_N_", "See [[N]]")

; 4. Integration (Mixed content)
; Input: "Sentence with [[S]].`n  Indented code."
; Core: "Sentence with [[S]].`n  Indented code."
InputText := "Sentence with [[S]].`n  Indented code."
MockRaw := "Sentence with AHK_ESC_S_.[[N]] [[S]] Indented code."
Expected := "Sentence with [[S]].`n  Indented code."
RunTest("Integration: Mixed sentence & code", InputText, MockRaw, Expected)

; 5. DeepL Resilience
RunTest("Resilience: Hallucinated Spaces", "  ", " [[ S ]] ", "  ")

; 6. User Specific Case (Russian + Code)
InputText := "Проверьте [[S]] для пробелов и [[N]] для новых строк.`n`ndef greet():`n    print(`"Привет`") "
MockRaw :=
    "Check AHK_ESC_S_ for spaces and AHK_ESC_N_ for newlines.[[N]][[N]]def greet():[[N]] [[S]]  [[S]] print(`"Hello`")"
Expected := "Check [[S]] for spaces and [[N]] for newlines.`n`ndef greet():`n    print(`"Hello`") "
RunTest("User Case: Russian/Code Integration", InputText, MockRaw, Expected)

; --- REPORT ---
ResultMsg := "Test Results: " . PassedTests . "/" . TotalTests . " Passed"
if (Failures != "") {
    MsgBox ResultMsg . "`n`nFailures:" . Failures, "Consolidated Test - FAILED", "Icon!"
} else {
    MsgBox ResultMsg . "`n`nAll consolidated integration tests passed.", "Consolidated Test - PASSED", "Iconi"
}
