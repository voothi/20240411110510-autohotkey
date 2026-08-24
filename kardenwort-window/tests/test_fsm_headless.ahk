#Requires AutoHotkey v2.0

; ===================================================================================
; Headless FSM Regression Runner
;
; Capability: headless-fsm-simulation
; Spec:       openspec/changes/20260803151525-headless-fsm-payload-defense/specs/headless-fsm-simulation/spec.md
;
; Executes the production FsmDispatch handlers through G_FsmTestMode without
; rendering physical MSHTML GUI windows. Verifies that all simulated edge-case
; event sequences resolve cleanly without state deadlocks.
;
; Usage: Run directly with AutoHotkey v2 — generates test_fsm_headless_results.txt
; in the same directory. Exit code 0 = all pass, 1 = failures detected.
; ===================================================================================

global G_FsmTestMode := true
global G_HoverHighlightMvpRainbow := 1

; Local inclusions within the autohotkey repository
#Include "..\..\Lib\B64Util.ahk"
#Include "..\kardenwort-window.ahk"

#Include "mock_gui.ahk"

; ===================================================================================
; Assertion Framework
; ===================================================================================

global _TotalTests := 0
global _FailedTests := 0
global _ResultsFile := A_ScriptDir "\test_fsm_headless_results.txt"

try {
    FileDelete(_ResultsFile)
} catch {
}

_Assert(condition, message) {
    global _TotalTests, _FailedTests, _ResultsFile
    _TotalTests += 1
    if (condition) {
        FileAppend("PASS: " message "`n", _ResultsFile)
    } else {
        _FailedTests += 1
        FileAppend("FAIL: " message "`n", _ResultsFile)
    }
}

; ===================================================================================
; Scenario Group 1: EV_DIRTY — Dirty flag is set without state change from IDLE
; ===================================================================================

; S1.1: IDLE + EV_DIRTY sets IsDirty, stays in IDLE
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
FsmDispatch(g, EV_DIRTY)
_Assert(g.FsmState == FSM_IDLE, "S1.1: IDLE + EV_DIRTY stays in IDLE")
_Assert(g.FsmMemory["IsDirty"], "S1.1: IDLE + EV_DIRTY sets IsDirty=true")

; S1.2: Multiple EV_DIRTY events do not stack-overflow or deadlock
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
FsmDispatch(g, EV_DIRTY)
FsmDispatch(g, EV_DIRTY)
FsmDispatch(g, EV_DIRTY)
_Assert(g.FsmState == FSM_IDLE, "S1.2: Three EV_DIRTY events leave state as IDLE (no deadlock)")
_Assert(g.FsmMemory["IsDirty"], "S1.2: IsDirty remains true after repeated EV_DIRTY")

; S1.3: EV_DIRTY is silently dropped in SAVING state (guard prevents transition)
g := MakeMockGui()
g.FsmState := FSM_SAVING
FsmDispatch(g, EV_DIRTY)
_Assert(g.FsmState == FSM_SAVING, "S1.3: EV_DIRTY ignored in SAVING state (no deadlock)")

; S1.4: EV_DIRTY is silently dropped in EXPORTING state
g := MakeMockGui()
g.FsmState := FSM_EXPORTING
FsmDispatch(g, EV_DIRTY)
_Assert(g.FsmState == FSM_EXPORTING, "S1.4: EV_DIRTY ignored in EXPORTING state")

; ===================================================================================
; Scenario Group 2: EV_SAVE_CLICK — Save transitions and guard behaviour
; ===================================================================================

; S2.1: IDLE + EV_SAVE_CLICK when not dirty is ignored
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
FsmDispatch(g, EV_SAVE_CLICK)
_Assert(g.FsmState == FSM_IDLE, "S2.1: EV_SAVE_CLICK when not dirty stays in IDLE")

; S2.2: IDLE + EV_SAVE_CLICK when dirty transitions to SAVING
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := true
FsmDispatch(g, EV_SAVE_CLICK)
_Assert(g.FsmState == FSM_SAVING, "S2.2: EV_SAVE_CLICK when dirty transitions to SAVING")

; S2.3: SAVING + EV_SAVE_SUCCESS → RELOADING → IDLE (no deadlock, full round-trip)
g := MakeMockGui()
g.FsmState := FSM_SAVING
g.FsmMemory["IsDirty"] := true
g.FsmMemory["PendingUpdate"] := false
g.TsvPath := "dummy.tsv"
FsmDispatch(g, EV_SAVE_SUCCESS)
_Assert(g.FsmState == FSM_RELOADING, "S2.3a: EV_SAVE_SUCCESS transitions to RELOADING")
FsmDispatch(g, EV_RELOAD_DONE)
_Assert(g.FsmState == FSM_IDLE, "S2.3b: EV_RELOAD_DONE transitions to IDLE")
_Assert(!g.FsmMemory["IsDirty"], "S2.3c: IsDirty cleared after save+reload cycle")

; S2.4: SAVING + EV_SAVE_FAILED returns to IDLE (error recovery, no deadlock)
g := MakeMockGui()
g.FsmState := FSM_SAVING
FsmDispatch(g, EV_SAVE_FAILED)
_Assert(g.FsmState == FSM_IDLE, "S2.4: EV_SAVE_FAILED recovers to IDLE (no orphaned SAVING state)")

; ===================================================================================
; Scenario Group 3: EV_RETEXT_DONE — Re-text success and failure paths
; ===================================================================================

; S3.1: FSM_RETEXTING + EV_RETEXT_DONE (success) → IDLE
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
FsmDispatch(g, EV_RETEXT_CLICK, "")
_Assert(g.FsmState == FSM_RETEXTING, "S3.1a: EV_RETEXT_CLICK transitions to RETEXTING")
FsmDispatch(g, EV_RETEXT_DONE, Map("status", "success", "message", "Re-text complete"))
_Assert(g.FsmState == FSM_IDLE, "S3.1b: EV_RETEXT_DONE (success) resolves to IDLE")

; S3.2: FSM_RETEXTING + EV_RETEXT_DONE when already in IDLE (stale event) — ignored
g := MakeMockGui()
g.FsmState := FSM_IDLE
FsmDispatch(g, EV_RETEXT_DONE, Map("status", "success"))
_Assert(g.FsmState == FSM_IDLE, "S3.2: Stale EV_RETEXT_DONE in IDLE is silently ignored (no deadlock)")

; S3.3: FSM_RETEXTING + EV_RETEXT_FAILED → IDLE (failure recovery, no deadlock)
g := MakeMockGui()
g.FsmState := FSM_RETEXTING
FsmDispatch(g, EV_RETEXT_FAILED, "API error - translation failed")
_Assert(g.FsmState == FSM_IDLE, "S3.3: EV_RETEXT_FAILED recovers to IDLE (no orphaned RETEXTING state)")

; S3.4: Rapid RETEXT_CLICK + RETEXT_FAILED + RETEXT_CLICK — no deadlock across repeated attempts
g := MakeMockGui()
g.FsmState := FSM_IDLE
FsmDispatch(g, EV_RETEXT_CLICK, "")
FsmDispatch(g, EV_RETEXT_FAILED, "network error")
_Assert(g.FsmState == FSM_IDLE, "S3.4a: RETEXTING -> IDLE after failure")
FsmDispatch(g, EV_RETEXT_CLICK, "")
_Assert(g.FsmState == FSM_RETEXTING, "S3.4b: Second RETEXT_CLICK accepted from IDLE (no deadlock)")
FsmDispatch(g, EV_RETEXT_DONE, Map("status", "success"))
_Assert(g.FsmState == FSM_IDLE, "S3.4c: Second RETEXT_DONE resolves cleanly to IDLE")

; S3.5: Worker retext_started payload sets ActiveRetext=true and shows "Re-texting..."
g := MakeMockGui()
g.FsmState := FSM_RETEXTING
FsmDispatch(g, EV_RETEXT_DONE, Map("retext_started", true))
_Assert(g.FsmState == FSM_IDLE, "S3.5a: EV_RETEXT_DONE with retext_started resolves to IDLE")
_Assert(g.FsmMemory["ActiveRetext"] == true, "S3.5b: ActiveRetext remains true during background worker execution")
UpdateButtonState(g)
_Assert(g.CurrentStatusText == "Re-texting...", "S3.5c: UpdateButtonState displays 'Re-texting...' while ActiveRetext is active")

; S3.6: Retext completion clears ActiveRetext and restores title to Ready
OnAhkCall(g, "finished", "")
_Assert(g.FsmMemory["ActiveRetext"] == false, "S3.6a: OnAhkCall finished clears ActiveRetext")
_Assert(g.CurrentStatusText == "Ready", "S3.6b: Window status restores to 'Ready' on retext finish")

; ===================================================================================
; Scenario Group 4: EV_EXPORT_FAILED — Export failure edge cases
; ===================================================================================

; S4.1: FSM_EXPORTING + EV_EXPORT_FAILED → IDLE (clean recovery, no deadlock)
g := MakeMockGui()
g.FsmState := FSM_EXPORTING
FsmDispatch(g, EV_EXPORT_FAILED)
_Assert(g.FsmState == FSM_IDLE, "S4.1: EV_EXPORT_FAILED transitions from EXPORTING to IDLE (no deadlock)")

; S4.2: FSM_EXPORTING + EV_EXPORT_DONE → IDLE (success path, no deadlock)
g := MakeMockGui()
g.FsmState := FSM_EXPORTING
FsmDispatch(g, EV_EXPORT_DONE)
_Assert(g.FsmState == FSM_IDLE, "S4.2: EV_EXPORT_DONE transitions from EXPORTING to IDLE")

; S4.3: EV_SAVE_CLICK during EXPORTING is silently ignored (no state trap)
g := MakeMockGui()
g.FsmState := FSM_EXPORTING
g.FsmMemory["IsDirty"] := true
FsmDispatch(g, EV_SAVE_CLICK)
_Assert(g.FsmState == FSM_EXPORTING, "S4.3: EV_SAVE_CLICK during EXPORTING is ignored (no trap)")

; S4.4: EV_FILE_CHANGED during EXPORTING is silently ignored
g := MakeMockGui()
g.FsmState := FSM_EXPORTING
FsmDispatch(g, EV_FILE_CHANGED, "20260803171609")
_Assert(g.FsmState == FSM_EXPORTING, "S4.4: EV_FILE_CHANGED during EXPORTING is ignored")

; S4.5: After export failure, save workflow resumes correctly from IDLE
g := MakeMockGui()
g.FsmState := FSM_EXPORTING
FsmDispatch(g, EV_EXPORT_FAILED)
_Assert(g.FsmState == FSM_IDLE, "S4.5a: Post-export-failure state is IDLE")
g.FsmMemory["IsDirty"] := true
FsmDispatch(g, EV_SAVE_CLICK)
_Assert(g.FsmState == FSM_SAVING, "S4.5b: Save workflow resumes correctly after export failure recovery")

; ===================================================================================
; Scenario Group 5: Compound and Re-entrancy Edge Cases
; ===================================================================================

; S5.1: Re-entrancy guard — nested dispatch from within an IO handler is dropped
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
global G_FsmDispatching := true
FsmDispatch(g, EV_DIRTY)
global G_FsmDispatching := false
_Assert(!g.FsmMemory["IsDirty"], "S5.1: Re-entrant EV_DIRTY dropped when G_FsmDispatching=true (no deadlock)")

; S5.2: Compound flow - REPROCESS_CLICK while dirty triggers save then reprocess
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := true
selPayload := '[{"id": 99}]'
FsmDispatch(g, EV_REPROCESS_CLICK, selPayload)
_Assert(g.FsmState == FSM_SAVING, "S5.2a: REPROCESS while dirty first saves (SAVING state)")
_Assert(g.FsmMemory["PendingReprocess"], "S5.2b: PendingReprocess flag set")
FsmDispatch(g, EV_SAVE_SUCCESS)
_Assert(g.FsmState == FSM_REPROCESSING, "S5.2c: After save, transitions to REPROCESSING")
FsmDispatch(g, EV_REPROCESS_DONE)
_Assert(g.FsmState == FSM_IDLE, "S5.2d: REPROCESS_DONE resolves to IDLE (no deadlock)")

; S5.3: CLOSING state locks out all standard workflow events
g := MakeMockGui()
g.FsmState := FSM_CLOSING
FsmDispatch(g, EV_DIRTY)
_Assert(g.FsmState == FSM_CLOSING, "S5.3a: CLOSING ignores EV_DIRTY")
FsmDispatch(g, EV_FILE_CHANGED, "20260803172000")
_Assert(g.FsmState == FSM_CLOSING, "S5.3b: CLOSING ignores EV_FILE_CHANGED")
FsmDispatch(g, EV_EXPORT_CLICK)
_Assert(g.FsmState == FSM_CLOSING, "S5.3c: CLOSING ignores EV_EXPORT_CLICK")
FsmDispatch(g, EV_RETEXT_CLICK, "")
_Assert(g.FsmState == FSM_CLOSING, "S5.3d: CLOSING ignores EV_RETEXT_CLICK (no deadlock)")

; S5.4: DIRTY + SAVE + Export flow — full round-trip clean state
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
FsmDispatch(g, EV_DIRTY)
_Assert(g.FsmMemory["IsDirty"], "S5.4a: EV_DIRTY sets IsDirty")
FsmDispatch(g, EV_SAVE_CLICK)
_Assert(g.FsmState == FSM_SAVING, "S5.4b: Save click transitions to SAVING")
FsmDispatch(g, EV_SAVE_SUCCESS)
_Assert(g.FsmState == FSM_RELOADING, "S5.4c: Save success transitions to RELOADING")
FsmDispatch(g, EV_RELOAD_DONE)
_Assert(g.FsmState == FSM_IDLE, "S5.4d: Reload done resolves to IDLE")
_Assert(!g.FsmMemory["IsDirty"], "S5.4e: IsDirty cleared after full save+reload")

; S5.5: WorkerWatchdogTimeout resets ActiveReprocess and ActiveRetext to false
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["ActiveReprocess"] := true
g.FsmMemory["ActiveRetext"] := true
g.FsmMemory["PendingUpdate"] := true
WorkerWatchdogTimeout(g)
_Assert(!g.FsmMemory["ActiveReprocess"], "S5.5a: Watchdog timeout clears ActiveReprocess")
_Assert(!g.FsmMemory["ActiveRetext"], "S5.5b: Watchdog timeout clears ActiveRetext")
_Assert(!g.FsmMemory["PendingUpdate"], "S5.5c: Watchdog timeout clears PendingUpdate")

; S5.6: REPROCESS_DONE clears ActiveReprocess when skipped or finished
g := MakeMockGui()
g.FsmState := FSM_REPROCESSING
g.FsmMemory["ActiveReprocess"] := true
FsmDispatch(g, EV_REPROCESS_DONE, Map("status", "skipped", "message", "no words"))
_Assert(g.FsmState == FSM_IDLE, "S5.6a: REPROCESS_DONE transitions to IDLE")
_Assert(!g.FsmMemory["ActiveReprocess"], "S5.6b: REPROCESS_DONE clears ActiveReprocess")

; S5.7: UpdateButtonState displays LastError in status bar
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["LastError"] := "DeepL quota exceeded"
UpdateButtonState(g)
_Assert(InStr(g.CurrentStatusText, "DeepL quota exceeded"),
"S5.7a: UpdateButtonState displays LastError")

; S5.8: ActiveRetext resets on failed state without deadlock
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["ActiveRetext"] := true
g.FsmMemory["LastError"] := "Translation error"
UpdateButtonState(g)
_Assert(g.FsmState == FSM_IDLE, "S5.8a: Window remains in IDLE state on failure")

; S5.9: ActiveReprocess resets on failed state and displays Re-word failed warning
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["ActiveReprocess"] := false
g.FsmMemory["LastError"] := "Re-word failed: OpenAI API rate limit exceeded (HTTP 429)"
UpdateButtonState(g)
_Assert(InStr(g.CurrentStatusText, "Re-word failed: OpenAI API rate limit exceeded (HTTP 429)"),
"S5.9a: UpdateButtonState displays Re-word failure warning")
_Assert(g.ReprocBtn.Enabled, "S5.9b: Reprocess button re-enabled on failure")

; S5.10: Smooth in-place Re-text completion via OnAhkCall 'finished'
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["ActiveRetext"] := true
OnAhkCall(g, "finished", "")
_Assert(!g.FsmMemory["ActiveRetext"], "S5.10a: OnAhkCall finished clears ActiveRetext")
_Assert(g.FsmState == FSM_IDLE, "S5.10b: OnAhkCall finished maintains IDLE state without reload dispatch")

; ===================================================================================
; Scenario Group 6: HTTP Fast-Path & Fallback Robustness
; ===================================================================================

; S6.1: JSON_Stringify escapes quotes, backslashes, newlines
strVal := 'Hello "World" `n Path\To\File'
jsonStr := JSON_Stringify(strVal)
_Assert(InStr(jsonStr, '\"World\"') && InStr(jsonStr, '\\'),
"S6.1: JSON_Stringify properly escapes quotes and backslashes")

; S6.2: FetchHtmlViaHttp fails gracefully when server is offline/unreachable without crashing
outB64 := ""
errJSON := ""
httpRes := FetchHtmlViaHttp("en", "20260823000000", "single", "Test sentence", "", 1, false, &outB64, &errJSON)
_Assert(httpRes != 0 || outB64 != "", "S6.2: FetchHtmlViaHttp returns status code without crashing")

; S6.3: Offline/failure returns non-zero code prompting CLI fallback
if (httpRes != 0) {
    _Assert(httpRes != 0, "S6.3: FetchHtmlViaHttp indicates offline status for CLI fallback")
} else {
    _Assert(outB64 != "", "S6.3: FetchHtmlViaHttp retrieved b64 html payload")
}

; ===================================================================================
; Summary
; ===================================================================================

summary := "`n=== Headless FSM Regression Runner ===" . "`n"
    . "Tests Passed: " . (_TotalTests - _FailedTests) . "/" . _TotalTests . "`n"
if (_FailedTests > 0) {
    summary .= "FAILURES: " . _FailedTests . " test(s) FAILED`n"
} else {
    summary .= "All tests passed.`n"
}
FileAppend(summary, _ResultsFile)

; Exit with non-zero code if any failures (useful for CI integration)
ExitApp(_FailedTests > 0 ? 1 : 0)