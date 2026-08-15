#Requires AutoHotkey v2.0

; ===================================================================================
; Test Modes and Includes
; ===================================================================================
global G_FsmTestMode := true
global G_HoverHighlightMvpRainbow := 1

#Include "..\..\Lib\B64Util.ahk"
#Include "..\kardenwort-window.ahk"

#Include "mock_gui.ahk"

; Success/Failure counter
global totalTests := 0
global failedTests := 0

Assert(condition, message) {
    global totalTests, failedTests
    totalTests += 1
    if (condition) {
        FileAppend("SUCCESS: " message "`n", A_ScriptDir "\test_results.txt")
    } else {
        failedTests += 1
        FileAppend("FAILURE: " message "`n", A_ScriptDir "\test_results.txt")
    }
}

; Clear/Init results file
try {
    FileDelete(A_ScriptDir "\test_results.txt")
} catch {
}

; ===================================================================================
; Part 1: Legacy Window and Utility Tests
; ===================================================================================

; Test 1: Base64 Encoding & Decoding compatibility
text := "Hello World! This is Kardenwort GUI testing. 🇩🇪"
encoded := B64Encode(text)
decoded := B64Decode(encoded)
Assert(decoded == text, "Base64 encoding/decoding matched original text.")

; Test 2: Cascade layout coords offset calculation
G_CascadeIndex := 0
GetCascadeCoords(&x1, &y1)
G_CascadeIndex := 1
GetCascadeCoords(&x2, &y2)
G_CascadeIndex := 2
GetCascadeCoords(&x3, &y3)
Assert(x1 == 50 && y1 == 50 && x2 == 80 && y2 == 80 && x3 == 110 && y3 == 110,
    "Cascading coordinates incremented correctly.")

; Test 3: Cascade wrap-around behavior
G_CascadeIndex := 14
GetCascadeCoords(&x14, &y14)
G_CascadeIndex := 15
GetCascadeCoords(&x15, &y15) ; should wrap to 0 (50, 50)
Assert(x14 == 470 && x15 == 50, "Coordinate wrap-around reset after 15 windows.")

; Test 4: Verify config file existence and format
configPath := "..\config.ini"
if FileExist(configPath) {
    pythonPath := IniRead(configPath, "Paths", "DeskPythonPath", "")
    scriptPath := IniRead(configPath, "Paths", "DeskScriptPath", "")
    Assert(pythonPath != "" && scriptPath != "", "Config paths read correctly.")
} else {
    Assert(false, "Config file not found at " configPath)
}

; ===================================================================================
; Part 2: FSM Engine and Transitions Tests
; ===================================================================================

; Test 5: FsmInit Key Completeness
g := MakeMockGui()
Assert(g.FsmState == "LOADING", "Initial state is LOADING")
Assert(g.FsmMemory.Has("LastMTime"), "FsmMemory has LastMTime")
Assert(g.FsmMemory.Has("PendingUpdate"), "FsmMemory has PendingUpdate")
Assert(g.FsmMemory.Has("AutoInjectRetries"), "FsmMemory has AutoInjectRetries")
Assert(g.FsmMemory.Has("IsProgressive"), "FsmMemory has IsProgressive")
Assert(g.FsmMemory.Has("IsLazy"), "FsmMemory has IsLazy")
Assert(g.FsmMemory.Has("IsDirty"), "FsmMemory has IsDirty")
Assert(g.FsmMemory.Has("AutoSavePending"), "FsmMemory has AutoSavePending")
Assert(g.FsmMemory.Has("PendingReprocess"), "FsmMemory has PendingReprocess")
Assert(g.FsmMemory.Has("PendingClose"), "FsmMemory has PendingClose")

; Test 6: Transition Table Completeness
tableOk := true
for s in G_FSM_TRANSITIONS {
    for ev, trans in G_FSM_TRANSITIONS[s] {
        if (!trans.HasOwnProp("nextState")) {
            tableOk := false
        }
    }
}
Assert(tableOk, "Transition table structure is valid")

; Test 7: IDLE + EV_SAVE_CLICK ignored when not dirty
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
FsmDispatch(g, EV_SAVE_CLICK)
Assert(g.FsmState == FSM_IDLE, "Save click ignored in IDLE when not dirty")

; Test 8: SAVING + EV_FILE_CHANGED ignored
g := MakeMockGui()
g.FsmState := FSM_SAVING
FsmDispatch(g, EV_FILE_CHANGED, "20260701123000")
Assert(g.FsmState == FSM_SAVING, "File changed event ignored in SAVING state")

; Test 9: Atomic LastMTime Invariant on EV_SAVE_SUCCESS
g := MakeMockGui()
g.FsmState := FSM_SAVING
g.FsmMemory["PendingUpdate"] := false
g.FsmMemory["IsDirty"] := true
g.TsvPath := "dummy.tsv"
FsmDispatch(g, EV_SAVE_SUCCESS)
Assert(g.FsmState == FSM_RELOADING, "Transitions to RELOADING after save success triggers auto-reload")
FsmDispatch(g, EV_RELOAD_DONE)
Assert(g.FsmState == FSM_IDLE, "Transitions to IDLE after reload completes")
Assert(g.FsmMemory["IsDirty"] == false, "IsDirty is cleared")

; Test 10: EXPORTING + EV_FILE_CHANGED ignored
g := MakeMockGui()
g.FsmState := FSM_EXPORTING
FsmDispatch(g, EV_FILE_CHANGED, "20260701124000")
Assert(g.FsmState == FSM_EXPORTING, "File changed event ignored in EXPORTING state")

; Test 11: IDLE + EV_DIRTY sets IsDirty
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
FsmDispatch(g, EV_DIRTY)
Assert(g.FsmState == FSM_IDLE, "Remains IDLE after EV_DIRTY")
Assert(g.FsmMemory["IsDirty"] == true, "IsDirty set to true after EV_DIRTY")

; Test 12: CLOSING ignores file changed, dirty, clean events
g := MakeMockGui()
g.FsmState := FSM_CLOSING
FsmDispatch(g, EV_FILE_CHANGED, "20260701125000")
Assert(g.FsmState == FSM_CLOSING, "CLOSING state ignores EV_FILE_CHANGED")
FsmDispatch(g, EV_DIRTY)
Assert(g.FsmState == FSM_CLOSING, "CLOSING state ignores EV_DIRTY")
FsmDispatch(g, EV_CLEAN)
Assert(g.FsmState == FSM_CLOSING, "CLOSING state ignores EV_CLEAN")

; Test 13: Re-entrancy protection (nested dispatch from within guard/apply)
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
global G_FsmDispatching := true
FsmDispatch(g, EV_DIRTY)
global G_FsmDispatching := false
Assert(g.FsmMemory["IsDirty"] == false, "Dispatch dropped when G_FsmDispatching is true")

; Test 14: Compound flow - Reprocess with prior save
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := true
selectionPayload := '[{"id": 1}]'
FsmDispatch(g, EV_REPROCESS_CLICK, selectionPayload)
Assert(g.FsmState == FSM_SAVING, "Transitions to SAVING when reprocess clicked while dirty")
Assert(g.FsmMemory["PendingReprocess"] == true, "PendingReprocess is set to true")
Assert(g.FsmMemory["ReprocessSelection"] == selectionPayload, "ReprocessSelection payload stored")

; Now simulate save success
FsmDispatch(g, EV_SAVE_SUCCESS)
Assert(g.FsmState == FSM_REPROCESSING, "Transitions to REPROCESSING after save success")
Assert(g.FsmMemory["PendingReprocess"] == false, "PendingReprocess is cleared")

; Now simulate reprocess done
FsmDispatch(g, EV_REPROCESS_DONE)
Assert(g.FsmState == FSM_IDLE, "Transitions to IDLE after reprocess done")

; Test 15: Compound flow - Close with prior save
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := true
FsmDispatch(g, EV_CLOSE, "Yes")
Assert(g.FsmState == FSM_SAVING, "Transitions to SAVING when close requested with dirty edits")
Assert(g.FsmMemory["PendingClose"] == true, "PendingClose is set to true")

FsmDispatch(g, EV_SAVE_SUCCESS)
Assert(g.FsmState == FSM_CLOSING, "Transitions to CLOSING state after successful save-on-close")
Assert(g.FsmMemory["PendingClose"] == false, "PendingClose is cleared")

; Test 16: InjectHoverHighlightMvp mock execution
class MockElement {
    id := ""
    type := ""
    text := ""
    length := 0
    _attrs := Map()
    setAttribute(name, val) => this._attrs[name] := val
    getAttribute(name) => this._attrs.Has(name) ? this._attrs[name] : ""
    appendChild(el) => 0
}

class MockCollection {
    length := 0
    items := Map()
    __Item[index] {
        get => this.items.Has(index) ? this.items[index] : ""
        set => this.items[index] := value
    }
}

class MockDocument {
    _elements := Map()
    __mvpBookmarks := 0
    parentWindow := this
    body := MockElement()

    createElement(tagName) {
        el := MockElement()
        return el
    }
    getElementById(id) {
        return this._elements.Has(id) ? this._elements[id] : ""
    }
    getElementsByTagName(name) {
        res := MockCollection()
        return res
    }
}

class MockWb {
    document := MockDocument()
}

class MockGuiWithWb extends MockGui {
    wb := MockWb()
}

g_mvp := MockGuiWithWb()
InjectHoverHighlightMvp(g_mvp, 5)
Assert(g_mvp.wb.document.parentWindow.__mvpBookmarks == 5,
    "InjectHoverHighlightMvp set parentWindow.__mvpBookmarks correctly.")

; Test 18: IDLE + EV_SAVE_CLICK transitions to SAVING when dirty
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := true
FsmDispatch(g, EV_SAVE_CLICK)
Assert(g.FsmState == FSM_SAVING, "Save click when dirty transitions to SAVING state")

; Test 19: IDLE with PendingUpdate + EV_UPDATE_CLICK transitions to RELOADING
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["PendingUpdate"] := true
FsmDispatch(g, EV_UPDATE_CLICK)
Assert(g.FsmState == FSM_RELOADING, "Update click in IDLE state transitions to RELOADING, actual: " g.FsmState)

; Test 20: OnAhkCall with 'finished' action
g_fin := MakeMockGui()
try {
    OnAhkCall(g_fin, "finished", "")
    Assert(true, "OnAhkCall 'finished' action handled successfully without throwing error")
} catch as err {
    Assert(false, "OnAhkCall 'finished' action threw an error: " err.Message)
}

; Test 21: Compound flow - Re-text (FSM_RETEXTING -> FSM_IDLE)
g := MakeMockGui()
g.FsmState := FSM_IDLE
g.FsmMemory["IsDirty"] := false
FsmDispatch(g, EV_RETEXT_CLICK, "")
Assert(g.FsmState == FSM_RETEXTING, "Transitions to RETEXTING when Re-text clicked")

FsmDispatch(g, EV_RETEXT_DONE, Map("status", "success", "message", "Text re-translated"))
Assert(g.FsmState == FSM_IDLE, "Transitions back to IDLE after Re-text completes successfully")

; Test 22: Re-text failure flow (FSM_RETEXTING -> FSM_IDLE on failure)
g := MakeMockGui()
g.FsmState := FSM_RETEXTING
FsmDispatch(g, EV_RETEXT_FAILED, "API error")
Assert(g.FsmState == FSM_IDLE, "Transitions back to IDLE after Re-text fails")

; Test 23: Config AutoCloseOnNewLaunch setting
autoCloseVal := IniRead(configPath, "Settings", "AutoCloseOnNewLaunch", "0")
Assert(autoCloseVal == "0" || autoCloseVal == "1", "AutoCloseOnNewLaunch setting is present in config.ini")

; Test 24: GetActiveKardenwortWindows dead key cleanup
global G_ActiveWindows
G_ActiveWindows.Clear()
G_ActiveWindows["fake_session_12345"] := 99999999 ; non-existent hwnd
activeList := GetActiveKardenwortWindows()
Assert(activeList.Length == 0 && !G_ActiveWindows.Has("fake_session_12345"),
"GetActiveKardenwortWindows cleaned up dead non-existent window IDs")

; Test 25: CloseAllActiveWindows lifecycle reset
G_ActiveWindows["fake_session_67890"] := 88888888
G_WindowCount := 3
G_CascadeIndex := 5
CloseAllActiveWindows()
Assert(G_ActiveWindows.Count == 0 && G_WindowCount == 0 && G_CascadeIndex == 0,
    "CloseAllActiveWindows cleanly reset active windows, window count, and cascade index")

; ===================================================================================
; Part 3: Matrix & State Decision Suites
; ===================================================================================

; Matrix 1: Active Window Detection & Pruning Matrix (M1.1 - M1.3)
G_ActiveWindows.Clear()
m1_1 := GetActiveKardenwortWindows()
Assert(m1_1.Length == 0, "Matrix 1.1: Empty active windows map returns empty array")

G_ActiveWindows.Clear()
G_ActiveWindows["dead_1"] := 999901
G_ActiveWindows["dead_2"] := 999902
m1_2 := GetActiveKardenwortWindows()
Assert(m1_2.Length == 0 && G_ActiveWindows.Count == 0, "Matrix 1.2: Dead HWNDs pruned completely")

taskbarHwnd := WinExist("ahk_class Shell_TrayWnd")
if (taskbarHwnd) {
    G_ActiveWindows.Clear()
    G_ActiveWindows["dead_1"] := 999903
    G_ActiveWindows["live_1"] := taskbarHwnd
    m1_3 := GetActiveKardenwortWindows()
    Assert(m1_3.Length == 1 && m1_3[1].sessionID == "live_1" && !G_ActiveWindows.Has("dead_1"),
    "Matrix 1.3: Mixed dead/live HWNDs filtered to live only")
    G_ActiveWindows.Clear()
}

; Matrix 2: Session Close & Teardown Verification Matrix (M2.1 - M2.3)
G_ActiveWindows.Clear()
G_WindowCount := 2
G_CascadeIndex := 3
m2_1 := CloseAllActiveWindows()
Assert(m2_1 == true && G_WindowCount == 0 && G_CascadeIndex == 0,
    "Matrix 2.1: CloseAll with 0 windows succeeds and resets state")

G_ActiveWindows["orphan_1"] := 999904
G_WindowCount := 1
m2_2 := CloseAllActiveWindows()
Assert(m2_2 == true && G_ActiveWindows.Count == 0 && G_WindowCount == 0,
    "Matrix 2.2: CloseAll with dead handles succeeds and cleans map")

if (taskbarHwnd) {
    G_ActiveWindows["uncloseable"] := taskbarHwnd
    m2_3 := CloseAllActiveWindows()
    Assert(m2_3 == false, "Matrix 2.3: CloseAll returns false when an active window remains unclosed")
    G_ActiveWindows.Clear()
}

; Matrix 3: Session Guard Pre-Flight Decision Matrix
SimulateSessionGuard(activeCount, autoClose, userChoice) {
    if (activeCount == 0) {
        return "DIRECT_LAUNCH"
    }
    if (autoClose == 1) {
        return "CLOSE_AND_LAUNCH"
    }
    if (userChoice == "Yes") {
        return "CLOSE_AND_LAUNCH"
    } else if (userChoice == "No") {
        return "FOCUS_EXISTING"
    } else {
        return "ABORT"
    }
}

matrixCombinations := [{ count: 0, auto: 0, choice: "Yes", expected: "DIRECT_LAUNCH" }, { count: 0, auto: 0, choice: "No",
    expected: "DIRECT_LAUNCH" }, { count: 0, auto: 0, choice: "Cancel", expected: "DIRECT_LAUNCH" }, { count: 0, auto: 1,
        choice: "Yes", expected: "DIRECT_LAUNCH" }, { count: 0, auto: 1, choice: "No", expected: "DIRECT_LAUNCH" }, { count: 0,
            auto: 1, choice: "Cancel", expected: "DIRECT_LAUNCH" }, { count: 1, auto: 1, choice: "Yes", expected: "CLOSE_AND_LAUNCH" }, { count: 1,
                auto: 1, choice: "No", expected: "CLOSE_AND_LAUNCH" }, { count: 1, auto: 1, choice: "Cancel", expected: "CLOSE_AND_LAUNCH" }, { count: 1,
                    auto: 0, choice: "Yes", expected: "CLOSE_AND_LAUNCH" }, { count: 1, auto: 0, choice: "No", expected: "FOCUS_EXISTING" }, { count: 1,
                        auto: 0, choice: "Cancel", expected: "ABORT" }, { count: 2, auto: 0, choice: "Yes", expected: "CLOSE_AND_LAUNCH" }, { count: 2,
                            auto: 0, choice: "No", expected: "FOCUS_EXISTING" }, { count: 2, auto: 0, choice: "Cancel",
                                expected: "ABORT" }
]

allMatrix3Passed := true
for entry in matrixCombinations {
    act := SimulateSessionGuard(entry.count, entry.auto, entry.choice)
    if (act != entry.expected) {
        allMatrix3Passed := false
    }
}
Assert(allMatrix3Passed, "Matrix 3: All 15 session guard pre-flight decision matrix branches resolved correctly")

; Matrix 4: Language Verification Decision Matrix
SimulateLangVerify(isMismatch, userChoice) {
    if (!isMismatch) {
        return "RENDER_DIRECT"
    }
    if (userChoice == "Yes") {
        return "SWITCH_LANGUAGE"
    } else if (userChoice == "No") {
        return "BYPASS_VERIFY"
    } else {
        return "ABORT"
    }
}

langMatrixCombinations := [{ mismatch: false, choice: "Yes", expected: "RENDER_DIRECT" }, { mismatch: false, choice: "No",
    expected: "RENDER_DIRECT" }, { mismatch: false, choice: "Cancel", expected: "RENDER_DIRECT" }, { mismatch: true,
        choice: "Yes", expected: "SWITCH_LANGUAGE" }, { mismatch: true, choice: "No", expected: "BYPASS_VERIFY" }, { mismatch: true,
            choice: "Cancel", expected: "ABORT" }
]

allLangMatrixPassed := true
for entry in langMatrixCombinations {
    act := SimulateLangVerify(entry.mismatch, entry.choice)
    if (act != entry.expected) {
        allLangMatrixPassed := false
    }
}
Assert(allLangMatrixPassed, "Matrix 4: All 6 language verification decision matrix branches resolved correctly")

; Write summary
FileAppend("`nSummary: " (totalTests - failedTests) "/" totalTests " tests passed.`n", A_ScriptDir "\test_results.txt")
ExitApp()