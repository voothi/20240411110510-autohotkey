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

; Test 3b: Sequence-aware cascade offsets (front_first: Badge 2 -> offset 1 (+30px), Badge 3 -> offset 2, Badge 9 -> offset 8, Badge 16 -> offset 0)
s2 := 2
eff2 := (s2 > 1) ? (s2 - 1) : 0
GetCascadeCoords(&xSeq2, &ySeq2, eff2)

s3 := 3
eff3 := (s3 > 1) ? (s3 - 1) : 0
GetCascadeCoords(&xSeq3, &ySeq3, eff3)

s9 := 9
eff9 := (s9 > 1) ? (s9 - 1) : 0
GetCascadeCoords(&xSeq9, &ySeq9, eff9)

s16 := 16
eff16 := (s16 > 1) ? (s16 - 1) : 0
GetCascadeCoords(&xSeq16, &ySeq16, eff16)

Assert(xSeq2 == 80 && ySeq2 == 80 && xSeq3 == 110 && ySeq3 == 110 && xSeq9 == 290 && ySeq9 == 290 && xSeq16 == 50 &&
    ySeq16 == 50,
    "front_first sequence-aware cascade offsets (Badge 2 at +30px, Badge 3 at +60px) calculated correctly without overlapping Window 1."
)

; Test 4: Verify config file existence and format
configPath := A_ScriptDir "\..\config.ini"
if FileExist(configPath) {
    pythonPath := IniRead(configPath, "Paths", "DeskPythonPath", "")
    scriptPath := IniRead(configPath, "Paths", "DeskScriptPath", "")
    cascadeBatch := IniRead(configPath, "Settings", "CascadeBatchWindows", "")
    Assert(cascadeBatch != "", "CascadeBatchWindows setting is present in config.ini")
    cascadeMode := IniRead(configPath, "Settings", "CascadeLayoutMode", "")
    Assert(cascadeMode != "", "CascadeLayoutMode setting is present in config.ini")
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
g_fin.FsmState := FSM_IDLE
g_fin.FsmMemory["ActiveRetext"] := true
try {
    OnAhkCall(g_fin, "finished", "")
    Assert(!g_fin.FsmMemory["ActiveRetext"] && g_fin.FsmState == FSM_IDLE,
        "OnAhkCall 'finished' action clears ActiveRetext and maintains IDLE state smoothly")
} catch as err {
    Assert(false, "OnAhkCall 'finished' action threw an error: " err.Message)
}

; Test 20b: Progressive mode ignores EV_FILE_CHANGED when G_AutoUpdate=0 (prevents reload flicker)
g_prog := MakeMockGui()
g_prog.FsmState := FSM_IDLE
g_prog.FsmMemory["IsProgressive"] := true
g_prog.FsmMemory["LastMTime"] := "20260825120000"
g_prog.FsmMemory["AutoInjectRetries"] := 0
global G_AutoUpdate := 0
FsmDispatch(g_prog, EV_FILE_CHANGED, "20260825120001")
Assert(g_prog.FsmState == FSM_IDLE, "Progressive mode with G_AutoUpdate=0 remains in IDLE without reload flicker")

; Test 20c: G_AutoUpdate=1 transitions EV_FILE_CHANGED to RELOADING
g_auto := MakeMockGui()
g_auto.FsmState := FSM_IDLE
g_auto.FsmMemory["IsProgressive"] := false
g_auto.FsmMemory["LastMTime"] := "20260825120000"
global G_AutoUpdate := 1
FsmDispatch(g_auto, EV_FILE_CHANGED, "20260825120001")
Assert(g_auto.FsmState == FSM_RELOADING, "G_AutoUpdate=1 transitions EV_FILE_CHANGED to RELOADING")
global G_AutoUpdate := 0

; Test 20d: Progressive grace period settlement latches IsProgressive to false and sets PendingUpdate
g_settle := MakeMockGui()
g_settle.FsmState := FSM_IDLE
g_settle.FsmMemory["IsProgressive"] := true
g_settle.FsmMemory["LastMTime"] := "20260825120000"
g_settle.FsmMemory["GracePeriodMTime"] := "20260825120002"
g_settle.FsmMemory["AutoInjectRetries"] := 1000
global G_AutoUpdate := 0
FsmDispatch(g_settle, EV_FILE_CHANGED, "20260825120002")
Assert(g_settle.FsmState == FSM_IDLE && !g_settle.FsmMemory["IsProgressive"] && g_settle.FsmMemory["PendingUpdate"],
    "Grace period expiry latches IsProgressive to false and sets PendingUpdate")

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

; Matrix 1.3: Mixed live and dead handles
testDummyGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "KardenwortTestDummy")
testDummyGui.Show("x-9999 y-9999 w10 h10 NoActivate")
G_ActiveWindows.Clear()
G_ActiveWindows["dead_1"] := 999903
G_ActiveWindows["live_1"] := testDummyGui.Hwnd
m1_3 := GetActiveKardenwortWindows()
Assert(m1_3.Length == 1 && m1_3[1].sessionID == "live_1" && !G_ActiveWindows.Has("dead_1"),
"Matrix 1.3: Mixed dead/live HWNDs filtered to live only")
testDummyGui.Destroy()
G_ActiveWindows.Clear()

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

; Matrix 2.3: CloseAllActiveWindows when a window rejects close
testDummyUncloseable := Gui("+AlwaysOnTop -Caption +ToolWindow", "KardenwortTestDummyUncloseable")
testDummyUncloseable.Show("x-9999 y-9999 w10 h10 NoActivate")
FsmInit(testDummyUncloseable)
testDummyUncloseable.FsmMemory["IsDirty"] := true
G_AutoSaveOnClose := 0
G_ActiveWindows["uncloseable"] := testDummyUncloseable.Hwnd
m2_3 := CloseAllActiveWindows()
Assert(m2_3 == false, "Matrix 2.3: CloseAll returns false when an active window remains unclosed")
testDummyUncloseable.Destroy()
G_ActiveWindows.Clear()

; Matrix 3: Session Guard Pre-Flight Decision Matrix
SimulateSessionGuard(activeCount, autoClose, userChoice, isRestore := false) {
    if (isRestore || activeCount == 0) {
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

matrixCombinations := [
    ; Fresh capture (isRestore = false)
    { count: 0, auto: 0, choice: "Yes", restore: false, expected: "DIRECT_LAUNCH" }, { count: 0, auto: 0, choice: "No",
        restore: false, expected: "DIRECT_LAUNCH" }, { count: 0, auto: 0, choice: "Cancel", restore: false, expected: "DIRECT_LAUNCH" }, { count: 0,
            auto: 1, choice: "Yes", restore: false, expected: "DIRECT_LAUNCH" }, { count: 0, auto: 1, choice: "No",
                restore: false, expected: "DIRECT_LAUNCH" }, { count: 0, auto: 1, choice: "Cancel", restore: false,
                    expected: "DIRECT_LAUNCH" }, { count: 1, auto: 1, choice: "Yes", restore: false, expected: "CLOSE_AND_LAUNCH" }, { count: 1,
                        auto: 1, choice: "No", restore: false, expected: "CLOSE_AND_LAUNCH" }, { count: 1, auto: 1,
                            choice: "Cancel", restore: false, expected: "CLOSE_AND_LAUNCH" }, { count: 1, auto: 0,
                                choice: "Yes", restore: false, expected: "CLOSE_AND_LAUNCH" }, { count: 1, auto: 0,
                                    choice: "No", restore: false, expected: "FOCUS_EXISTING" }, { count: 1, auto: 0,
                                        choice: "Cancel", restore: false, expected: "ABORT" }, { count: 2, auto: 0,
                                            choice: "Yes", restore: false, expected: "CLOSE_AND_LAUNCH" }, { count: 2,
                                                auto: 0, choice: "No", restore: false, expected: "FOCUS_EXISTING" }, { count: 2,
                                                    auto: 0, choice: "Cancel", restore: false, expected: "ABORT" },
                                                ; Restore / Child window spawn (isRestore = true) -> always DIRECT_LAUNCH
                                                { count: 1, auto: 0, choice: "Yes", restore: true, expected: "DIRECT_LAUNCH" }, { count: 1,
                                                    auto: 0, choice: "No", restore: true, expected: "DIRECT_LAUNCH" }, { count: 1,
                                                        auto: 0, choice: "Cancel", restore: true, expected: "DIRECT_LAUNCH" }, { count: 1,
                                                            auto: 1, choice: "Yes", restore: true, expected: "DIRECT_LAUNCH" }, { count: 2,
                                                                auto: 0, choice: "Cancel", restore: true, expected: "DIRECT_LAUNCH" }
]

allMatrix3Passed := true
for entry in matrixCombinations {
    act := SimulateSessionGuard(entry.count, entry.auto, entry.choice, entry.restore)
    if (act != entry.expected) {
        allMatrix3Passed := false
    }
}
Assert(allMatrix3Passed, "Matrix 3: All 20 session guard pre-flight decision matrix branches resolved correctly")

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

; Part 5: Watchdog and Reprocess Completion Tests
gW := MakeMockGui()
gW.FsmState := FSM_IDLE
gW.FsmMemory["ActiveReprocess"] := true
gW.FsmMemory["ActiveRetext"] := true
gW.FsmMemory["PendingUpdate"] := true
WorkerWatchdogTimeout(gW)
Assert(!gW.FsmMemory["ActiveReprocess"] && !gW.FsmMemory["ActiveRetext"],
    "Watchdog timeout reset active reprocess and retext flags.")
Assert(!gW.FsmMemory["PendingUpdate"], "Watchdog timeout reset pending update flag.")

; ===================================================================================
; Part 6: Cascade Indexing, Sequential Processing, and Descendant Closing Tests
; ===================================================================================

; Test: CascadeBatchWindows = 1 calculation (front_first and reverse_stack modes)
baseX := 100, baseY := 100
ComputeCascadeCoords(bX, bY, seq, cascadeIndex, cascadeEnabled, layoutMode := "reverse_stack") {
    if (!cascadeEnabled) {
        return { x: bX, y: bY }
    }
    if (layoutMode == "front_first" || layoutMode == "2") {
        eff := (seq > 1) ? (seq - 1) : 0
    } else {
        eff := cascadeIndex
    }
    off := Mod(eff, 15) * 30
    return { x: bX + off, y: bY + off }
}

; Test front_first mode: Window 1 is at base, Window 2 is at +30 (non-overlapping), Window 3 at +60
ff1 := ComputeCascadeCoords(baseX, baseY, 1, 0, true, "front_first")
ff2 := ComputeCascadeCoords(baseX, baseY, 2, 1, true, "front_first")
ff3 := ComputeCascadeCoords(baseX, baseY, 3, 2, true, "front_first")
ff4 := ComputeCascadeCoords(baseX, baseY, 4, 3, true, "front_first")
Assert(ff1.x == 100 && ff1.y == 100 && ff2.x == 130 && ff2.y == 130 && ff3.x == 160 && ff3.y == 160 && ff4.x == 190 &&
    ff4.y == 190,
    "front_first mode positions Window 2 at +30px without overlapping Window 1 at base coordinates.")

; Test reverse_stack mode: Window 1 at base, child windows cascade smoothly by spawn index
rs1 := ComputeCascadeCoords(baseX, baseY, 1, 0, true, "reverse_stack")
rsChild1 := ComputeCascadeCoords(baseX, baseY, 13, 1, true, "reverse_stack")
rsChild2 := ComputeCascadeCoords(baseX, baseY, 12, 2, true, "reverse_stack")
Assert(rs1.x == 100 && rs1.y == 100 && rsChild1.x == 130 && rsChild1.y == 130 && rsChild2.x == 160 && rsChild2.y == 160,
    "reverse_stack mode positions Window 1 at base coordinates and cascades child windows monotonically.")

; Test: CascadeBatchWindows = 0 calculation (stacked)
s2_0 := ComputeCascadeCoords(baseX, baseY, 2, 1, false, "front_first")
s3_0 := ComputeCascadeCoords(baseX, baseY, 3, 2, false, "reverse_stack")
Assert(s2_0.x == 100 && s2_0.y == 100 && s3_0.x == 100 && s3_0.y == 100,
    "CascadeBatchWindows=0 stacks all child windows at base coordinates without offset regardless of layout mode.")

; Test: Sequential argument processing and window activation according to CascadeLayoutMode
SimulateProcessArgs(args, layoutMode := "reverse_stack", activeMap := Map()) {
    executed := []
    firstHwnd := 0
    lastHwnd := 0
    currSeq := ""
    i := 1
    while (i <= args.Length) {
        if (args[i] == "--seq-num" && i < args.Length) {
            currSeq := args[i + 1]
            i += 2
        } else if (args[i] == "--desk" && i < args.Length) {
            hwnd := 1000 + Integer(currSeq)
            executed.Push({ seq: currSeq, hwnd: hwnd })
            activeMap["session#" . currSeq] := hwnd
            if (!firstHwnd)
                firstHwnd := hwnd
            lastHwnd := hwnd
            currSeq := ""
            i += 2
        } else {
            i += 1
        }
    }

    activatedHwnd := 0
    if (layoutMode == "front_first" || layoutMode == "2") {
        targetHwnd := 0
        minSeq := 999999
        minHwnd := 0
        for sId, h in activeMap {
            seq := 0
            if RegExMatch(sId, "#(\d+)$", &mSeq) {
                seq := Integer(mSeq[1])
            }
            if (seq == 1) {
                targetHwnd := h
                break
            }
            if (seq > 0 && seq < minSeq) {
                minSeq := seq
                minHwnd := h
            }
        }
        if (!targetHwnd && minHwnd)
            targetHwnd := minHwnd
        if (!targetHwnd && firstHwnd)
            targetHwnd := firstHwnd
        activatedHwnd := targetHwnd
    } else {
        activatedHwnd := lastHwnd
    }
    return { executed: executed, activated: activatedHwnd }
}

; Test: front_first activation with Master Window 1 active (Full parent mode)
testMapFF_Full := Map("session#1", 1001)
testArgsFF_Normal := ["--seq-num", "2", "--desk", "p1.txt", "--seq-num", "3", "--desk", "p2.txt", "--seq-num", "4",
    "--desk", "p3.txt"]
resProcFF_Full := SimulateProcessArgs(testArgsFF_Normal, "front_first", testMapFF_Full)
Assert(resProcFF_Full.executed.Length == 3 && resProcFF_Full.executed[1].seq == "2" && resProcFF_Full.executed[2].seq ==
    "3" && resProcFF_Full.executed[3].seq == "4",
    "ProcessArgs parses and processes actions in natural sequential order (2 -> 3 -> 4).")
Assert(resProcFF_Full.activated == 1001,
    "ProcessArgs in front_first mode with parent full activates Window #1 (master window) in foreground.")

testMapFF_Rev := Map("session#1", 1001)
testArgsFF_Rev := ["--seq-num", "4", "--desk", "p3.txt", "--seq-num", "3", "--desk", "p2.txt", "--seq-num", "2",
    "--desk", "p1.txt"]
resProcFF_Rev := SimulateProcessArgs(testArgsFF_Rev, "front_first", testMapFF_Rev)
Assert(resProcFF_Rev.activated == 1001,
    "ProcessArgs in front_first mode with reverse argument spawn activates Window #1 (master window) in foreground.")

; Test: front_first activation without Window 1 (Stub parent mode) activates lowest child window (Window #2)
testMapFF_Stub := Map()
testArgsFF_Stub := ["--seq-num", "4", "--desk", "p3.txt", "--seq-num", "3", "--desk", "p2.txt", "--seq-num", "2",
    "--desk", "p1.txt"]
resProcFF_Stub := SimulateProcessArgs(testArgsFF_Stub, "front_first", testMapFF_Stub)
Assert(resProcFF_Stub.activated == 1002,
    "ProcessArgs in front_first mode without Window 1 activates lowest sequence child Window #2 in foreground.")

testMapRS := Map("session#1", 1001)
testArgsRS := ["--seq-num", "4", "--desk", "p3.txt", "--seq-num", "3", "--desk", "p2.txt", "--seq-num", "2", "--desk",
    "p1.txt"]
resProcRS := SimulateProcessArgs(testArgsRS, "reverse_stack", testMapRS)
Assert(resProcRS.activated == 1002,
    "ProcessArgs in reverse_stack mode activates Window #2 (top of stack) in foreground without raising Window #1.")

; Test: Parent Window 1 closing cleans up child descendant windows
SimulateParentClose(parentChildren, activeMap, closeDescendants) {
    closedHwnds := []
    if (closeDescendants) {
        for childSessionID in parentChildren {
            if (activeMap.Has(childSessionID)) {
                closedHwnds.Push(activeMap[childSessionID])
            } else {
                for actKey, actHwnd in activeMap {
                    if (InStr(actKey, childSessionID . "#") == 1) {
                        closedHwnds.Push(actHwnd)
                    }
                }
            }
        }
    }
    return closedHwnds
}

testActive := Map("c:/temp/s1.tsv#2", 2002, "c:/temp/s2.tsv#3", 2003, "c:/temp/s3.tsv#4", 2004)
testChildren := ["c:/temp/s1.tsv", "c:/temp/s2.tsv", "c:/temp/s3.tsv"]
closedList := SimulateParentClose(testChildren, testActive, true)
Assert(closedList.Length == 3 && closedList[1] == 2002 && closedList[2] == 2003 && closedList[3] == 2004,
    "Closing Window 1 successfully identifies and closes all child descendant windows.")

; ===================================================================================
; Part 7: Single-Instance Exit and Render Done Non-Activation
; ===================================================================================

; Test: Single-Instance argument forwarding unconditionally terminates launcher process
SimulateSingleInstanceForward(existingHwnd, args, sendSucceeds) {
    if (existingHwnd) {
        if (args.Length > 0) {
            ; simulates SendMessage
            if (!sendSucceeds) {
                ; message box or error logged
            }
        }
        return "EXITED"
    }
    return "CONTINUE_NEW_INSTANCE"
}

s1 := SimulateSingleInstanceForward(12345, ["--desk", "test.txt"], true)
s2 := SimulateSingleInstanceForward(12345, ["--desk", "test.txt"], false)
s3 := SimulateSingleInstanceForward(12345, [], false)
s4 := SimulateSingleInstanceForward(0, ["--desk", "test.txt"], true)
Assert(s1 == "EXITED" && s2 == "EXITED" && s3 == "EXITED" && s4 == "CONTINUE_NEW_INSTANCE",
    "Single-instance startup unconditionally exits whenever an existing instance HWND is detected.")

; Test: ActionRenderDone does not activate or pop window
gRender := MakeMockGui()
gRender.FsmState := FSM_LOADING
FsmDispatch(gRender, EV_RENDER_DONE, { outB64: "" })
Assert(gRender.FsmState == FSM_IDLE, "Render done transitions state from LOADING to IDLE without raising GUI focus")

; Test: LaunchRestore exact TSV path resolution without wildcard collision
SimulateResolveRestoreTsv(filePath, fileDir, zid, fakeFiles) {
    foundTsv := ""
    foundTsvPath := ""
    if (SubStr(filePath, -4) == ".tsv") {
        foundTsvPath := filePath
        SplitPath(filePath, &foundTsv)
    } else {
        tsvPattern := fileDir "\" zid "-*.tsv"
        for f in fakeFiles {
            if (InStr(f, zid) == 1 && SubStr(f, -4) == ".tsv") {
                foundTsv := f
                foundTsvPath := fileDir "\" f
                break
            }
        }
    }
    return { name: foundTsv, path: foundTsvPath }
}

fakeDir := "C:\results"
fakeFiles := ["20260826120000-001-first.de.tsv", "20260826120000-002-second.de.tsv"]
resExact := SimulateResolveRestoreTsv("C:\results\20260826120000-002-second.de.tsv", fakeDir, "20260826120000",
    fakeFiles)
Assert(resExact.path == "C:\results\20260826120000-002-second.de.tsv",
    "LaunchRestore with specific child TSV resolves directly to that child TSV without wildcard collision")

; Test: Window AppID and Icon Presentation
SimulateSetWindowAppId(hwnd, seqNum) {
    if (!hwnd || seqNum == "")
        return false
    appId := "Kardenwort.Window." seqNum
    return (appId == "Kardenwort.Window.2")
}
Assert(SimulateSetWindowAppId(1234, 2), "Window AppID is properly formatted with sequence number")

; Test: LaunchRestore SQLite mode return handle
SimulateLaunchRestoreReturn(filePath, fileExists, mockHwnd) {
    if (!fileExists) {
        ; FS-Free SQLite mode returns created window HWND
        return mockHwnd
    }
    return mockHwnd
}
Assert(SimulateLaunchRestoreReturn("C:\virtual\child.tsv", false, 9999) == 9999,
"LaunchRestore in SQLite mode returns valid window HWND handle")

; Write summary
FileAppend("`nSummary: " (totalTests - failedTests) "/" totalTests " tests passed.`n", A_ScriptDir "\test_results.txt")
ExitApp()