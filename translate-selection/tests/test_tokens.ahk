#Requires AutoHotkey v2.0

; ==============================================================================
; Test:         Robust Token Strategy
; Description:  Verifies escaping of literal tokens and restoration of functional
;               tokens (v1.48.15 logic).
; ==============================================================================

TotalTests := 0
PassedTests := 0
Failures := ""

; Mock of the TranslateSelection processing logic
SimulateProcessing(InputText, MockTranslatedRaw) {
    ProcessText := InputText

    ; PHASE 1: Collision Protection (Literal Escaping)
    ProcessText := StrReplace(ProcessText, "[[S]]", "AHK_ESC_S_")
    ProcessText := StrReplace(ProcessText, "[[B]]", "AHK_ESC_B_")
    ProcessText := StrReplace(ProcessText, "[[N]]", "AHK_ESC_N_")

    ; PHASE 2: Functional Tokenization (Simplified for Mock)
    ; In reality, ProcessText goes to API here.
    ; We assume MockTranslatedRaw contains the API result for the escaped ProcessText.
    TranslatedText := MockTranslatedRaw

    ; PHASE 3: Functional Restoration (From translate-selection.ahk)
    ; Restore functional tokens (which would have been created from spaces/newlines)
    TranslatedText := RegExReplace(TranslatedText, "i)\s*\[\[\s*B\s*\]\]\s*", "\")
    TranslatedText := RegExReplace(TranslatedText, "i)\s*\[\[\s*S\s*\]\]\s*", "  ")
    TranslatedText := RegExReplace(TranslatedText, "i)\[\[\s*N\s*\]\]", "`n")

    ; PHASE 3: Unescaping Literals
    TranslatedText := RegExReplace(TranslatedText, "i)AHK_ESC_S_", "[[S]]")
    TranslatedText := RegExReplace(TranslatedText, "i)AHK_ESC_B_", "[[B]]")
    TranslatedText := RegExReplace(TranslatedText, "i)AHK_ESC_N_", "[[N]]")

    return TranslatedText
}

RunTest(Description, InputText, MockTranslatedRaw, ExpectedOutput) {
    global TotalTests, PassedTests, Failures
    TotalTests++

    ActualOutput := SimulateProcessing(InputText, MockTranslatedRaw)

    if (ActualOutput == ExpectedOutput) {
        PassedTests++
    } else {
        Failures .= "`n- " . Description . ":`n  Expected: [" . ExpectedOutput . "]`n  Actual:   [" . ActualOutput .
            "]"
    }
}

; --- Test Cases ---

; 1. Functional Token Restoration (Backslashes)
; Input: "C:\" -> Processed: "C: [[B]]" (if path)
; Mock: "C: [[B]]" (API returns same) -> Final: "C:\"
RunTest("Functional Backslash", "C:\", "C: [[B]]", "C:\")

; 2. Functional Token Restoration (Spaces/Indentation)
; Mock: "Line1 [[N]]  [[S]]  Line2" -> Final: "Line1\n    Line2"
RunTest("Functional Indentation", "  ", "[[N]] [[S]]", "`n  ")

; 3. Collision Protection (Wikilinks)
; Input text contains literal [[S]]
; Processed: AHK_ESC_S_ -> Mock API: AHK_ESC_S_ -> Final: [[S]]
RunTest("Literal Wikilink [[S]]", "Note [[S]]", "Note AHK_ESC_S_", "Note [[S]]")

; 4. Mixed Functional and Literal (The "Bug" Case)
; Input: "Literal [[S]] and actual indentation."
; Phase 1 Escapes literal -> Phase 2 replaces actual spaces with [[S]]
; Mock Raw represents what comes back from API: "Literal AHK_ESC_S_ and [[S]] indentation"
RunTest("Mixed Literal and Functional", "[[S]]  ", "AHK_ESC_S_ [[S]]", "[[S]]  ")

; 5. DeepL Artifact Handling (Extra Spaces in Functional Tokens)
RunTest("DeepL Functional Artifacts", "  ", " [[ S ]] ", "  ")

; 6. Newline Strictness
RunTest("Newline Strictness", "`n", " [[N]] ", "`n")

; 7. Complex User Case (Wikilinks + Code Indentation)
; This ensures that literal tokens in a sentence AND functional tokens in a code block work together.
InputText := "Проверьте [[S]] для пробелов и [[N]] для новых строк.`n`ndef greet():`n    print(`"Привет`")"
; Mock Raw represents what the API might return (translated core + tokens)
MockRaw :=
    "Check AHK_ESC_S_ for spaces and AHK_ESC_N_ for newlines.[[N]][[N]]def greet():[[N]]  [[S]]  print(`"Hello`")"
Expected := "Check [[S]] for spaces and [[N]] for newlines.`n`ndef greet():`n    print(`"Hello`")"
RunTest("Complex User Case (Wikilink+Code)", InputText, MockRaw, Expected)

; --- Report ---
ResultMsg := "Tests Completed: " . PassedTests . "/" . TotalTests
if (Failures != "") {
    MsgBox ResultMsg . "`n`nFailures:" . Failures, "Token Logic Test - FAILED", "Icon!"
} else {
    MsgBox ResultMsg . "`n`nAll token logic tests passed successfully.", "Token Logic Test - PASSED", "Iconi"
}
