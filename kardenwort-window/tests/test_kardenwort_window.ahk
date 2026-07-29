#Requires AutoHotkey v2.0

; ===================================================================================
; Test Modes and Includes
; ===================================================================================
global G_FsmTestMode := true
global G_HoverHighlightMvpRainbow := 1

#Include "..\..\Lib\B64Util.ahk"
#Include "..\kardenwort-window.ahk"

; ===================================================================================
; Mock Setup for FSM tests
; ===================================================================================

class MockControl {
    Enabled := false
    Visible := false
    Text := ""
    Move(x?, y?, w?, h?) => 0
    Redraw() => 0
}

class MockGui {
    FsmState := ""
    FsmMemory := Map()
    ZID := "20260701120000"
    Lang := "en"
    TsvPath := "dummy.tsv"
    SourceText := "mock source text"
    TextMode := "single"
    StatusLog := []
    selectableTextMode := false

    SaveBtn := MockControl()
    UpdateBtn := MockControl()
    SendBtn := MockControl()
    DeleteBtn := MockControl()
    ReprocBtn := MockControl()
    RetextBtn := MockControl()
    PointerBtn := MockControl()
    StatusTxt := MockControl()

    GetClientPos(x?, y?, &w := 800, &h := 600) => 0
    Destroy() => 0
}

MakeMockGui() {
    g := MockGui()
    FsmInit(g)
    return g
}

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

; Write summary
FileAppend("`nSummary: " (totalTests - failedTests) "/" totalTests " tests passed.`n", A_ScriptDir "\test_results.txt")
ExitApp()