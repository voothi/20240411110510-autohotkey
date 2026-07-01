
; ===================================================================================
; FSM Constants
; ===================================================================================

; States
global FSM_LOADING := "LOADING"
global FSM_IDLE := "IDLE"
global FSM_SAVING := "SAVING"
global FSM_RELOADING := "RELOADING"
global FSM_REPROCESSING := "REPROCESSING"
global FSM_EXPORTING := "EXPORTING"
global FSM_CLOSING := "CLOSING"
global FSM_ERROR := "ERROR"

; Events
global EV_RENDER_DONE := "EV_RENDER_DONE"
global EV_RENDER_FAILED := "EV_RENDER_FAILED"
global EV_DIRTY := "EV_DIRTY"
global EV_CLEAN := "EV_CLEAN"
global EV_SAVE_CLICK := "EV_SAVE_CLICK"
global EV_SAVE_SUCCESS := "EV_SAVE_SUCCESS"
global EV_SAVE_FAILED := "EV_SAVE_FAILED"
global EV_FILE_CHANGED := "EV_FILE_CHANGED"
global EV_UPDATE_CLICK := "EV_UPDATE_CLICK"
global EV_RELOAD_DONE := "EV_RELOAD_DONE"
global EV_RELOAD_FAILED := "EV_RELOAD_FAILED"
global EV_REPROCESS_CLICK := "EV_REPROCESS_CLICK"
global EV_REPROCESS_DONE := "EV_REPROCESS_DONE"
global EV_REPROCESS_FAILED := "EV_REPROCESS_FAILED"
global EV_EXPORT_CLICK := "EV_EXPORT_CLICK"
global EV_EXPORT_DONE := "EV_EXPORT_DONE"
global EV_EXPORT_FAILED := "EV_EXPORT_FAILED"
global EV_CLOSE := "EV_CLOSE"

global FSM_AUTO_INJECT_MAX_RETRIES := 6
global G_FsmDispatching := false

; ===================================================================================
; FSM Engine
; ===================================================================================

FsmInit(guiObj) {
    guiObj.FsmState := FSM_LOADING
    guiObj.FsmMemory := Map(
        "LastMTime", "",
        "PendingUpdate", false,
        "AutoInjectRetries", 0,
        "IsProgressive", false,
        "IsLazy", false,
        "IsDirty", false,
        "AutoSavePending", false,
        "PendingReprocess", false,
        "PendingClose", false
    )
}

FsmDispatch(guiObj, event, payload := "") {
    global G_FSM_TRANSITIONS, G_FsmDispatching
    
    if (G_FsmDispatching) {
        if (!guiObj.HasOwnProp("StatusLog")) {
            guiObj.StatusLog := []
        }
        timeStr := FormatTime(A_Now, "HH:mm:ss")
        guiObj.StatusLog.InsertAt(1, "[" timeStr "] FSM: dropped re-entrant event " event " in state " guiObj.FsmState)
        if (guiObj.StatusLog.Length > 15) {
            guiObj.StatusLog.Pop()
        }
        return
    }

    currentState := guiObj.FsmState
    
    if (!G_FSM_TRANSITIONS.Has(currentState) || !G_FSM_TRANSITIONS[currentState].Has(event)) {
        return ; Silently ignore undefined transitions
    }

    transition := G_FSM_TRANSITIONS[currentState][event]
    
    ; Guard execution (if exists)
    if (transition.HasOwnProp("guard") && transition.guard != "") {
        guardFn := transition.guard
        if (!%guardFn%(guiObj, payload)) {
            return
        }
    }

    G_FsmDispatching := true
    
    ; Apply state mutation (if exists)
    nextState := transition.nextState
    if (transition.HasOwnProp("apply") && transition.apply != "") {
        applyFn := transition.apply
        nextState := %applyFn%(guiObj, payload)
    }

    guiObj.FsmState := nextState
    FsmLog(guiObj, currentState, nextState, event)
    
    ; IO side-effects (if exists)
    if (transition.HasOwnProp("io") && transition.io != "") {
        ioFn := transition.io
        %ioFn%(guiObj, payload)
    }
    
    G_FsmDispatching := false
}

FsmLog(guiObj, fromState, toState, event) {
    if (!guiObj.HasOwnProp("StatusLog")) {
        guiObj.StatusLog := []
    }
    timeStr := FormatTime(A_Now, "HH:mm:ss")
    msg := "[" timeStr "] FSM: " fromState " -> " toState " (" event ") @" guiObj.ZID
    guiObj.StatusLog.InsertAt(1, msg)
    if (guiObj.StatusLog.Length > 15) {
        guiObj.StatusLog.Pop()
    }
}

FsmSelfCheck() {
    global G_FSM_TRANSITIONS
    validStates := Map(FSM_LOADING, 1, FSM_IDLE, 1, FSM_SAVING, 1, FSM_RELOADING, 1, FSM_REPROCESSING, 1, FSM_EXPORTING, 1, FSM_CLOSING, 1, FSM_ERROR, 1)
    validEvents := Map(EV_RENDER_DONE, 1, EV_RENDER_FAILED, 1, EV_DIRTY, 1, EV_CLEAN, 1, EV_SAVE_CLICK, 1, EV_SAVE_SUCCESS, 1, EV_SAVE_FAILED, 1, EV_FILE_CHANGED, 1, EV_UPDATE_CLICK, 1, EV_RELOAD_DONE, 1, EV_RELOAD_FAILED, 1, EV_REPROCESS_CLICK, 1, EV_REPROCESS_DONE, 1, EV_REPROCESS_FAILED, 1, EV_EXPORT_CLICK, 1, EV_EXPORT_DONE, 1, EV_EXPORT_FAILED, 1, EV_CLOSE, 1)

    for state, events in G_FSM_TRANSITIONS {
        if (!validStates.Has(state)) {
            MsgBox("FSM Self-Check Failed: Invalid state '" state "' in transition table.", "Kardenwort FSM Error", 16)
            ExitApp()
        }
        for ev, trans in events {
            if (!validEvents.Has(ev)) {
                MsgBox("FSM Self-Check Failed: Invalid event '" ev "' in transition table.", "Kardenwort FSM Error", 16)
                ExitApp()
            }
        }
    }
}

; Define stubs for actions so the transition table parses
ActionRenderDoneGuard(g, p) {
    return true 

}
ActionRenderDoneApply(g, p) {
    return FSM_IDLE 

}
ActionRenderDoneIO(g, p) {
    return
}

ActionRenderFailedGuard(g, p) {
    return true 

}
ActionRenderFailedApply(g, p) {
    return FSM_ERROR 

}
ActionRenderFailedIO(g, p) {
    return
}

ActionDirtyApply(g, p) {
    return FSM_IDLE 

}
ActionCleanApply(g, p) {
    return FSM_IDLE 

}

ActionSaveStartGuard(g, p) {
    return true 

}
ActionSaveStartApply(g, p) {
    return FSM_SAVING 

}
ActionSaveStartIO(g, p) {
    return
}

ActionSaveSuccessApply(g, p) {
    return FSM_IDLE 

}
ActionSaveFailedApply(g, p) {
    return FSM_IDLE 

}

ActionFileChangedGuard(g, p) {
    return true 

}
ActionFileChangedApply(g, p) {
    return FSM_IDLE 

}

ActionUpdateClickApply(g, p) {
    return FSM_RELOADING 

}
ActionUpdateClickIO(g, p) {
    return
}

ActionReloadDoneApply(g, p) {
    return FSM_IDLE 

}
ActionReloadDoneIO(g, p) {
    return
}

ActionReloadFailedApply(g, p) {
    return FSM_IDLE 

}
ActionReloadFailedIO(g, p) {
    return
}

ActionReprocessStartGuard(g, p) {
    return true 

}
ActionReprocessStartApply(g, p) {
    return FSM_REPROCESSING 

}
ActionReprocessStartIO(g, p) {
    return
}

ActionReprocessDoneApply(g, p) {
    return FSM_IDLE 

}
ActionReprocessDoneIO(g, p) {
    return
}

ActionReprocessFailedApply(g, p) {
    return FSM_IDLE 

}
ActionReprocessFailedIO(g, p) {
    return
}

ActionExportStartGuard(g, p) {
    return true 

}
ActionExportStartApply(g, p) {
    return FSM_EXPORTING 

}
ActionExportStartIO(g, p) {
    return
}

ActionExportDoneApply(g, p) {
    return FSM_IDLE 

}
ActionExportDoneIO(g, p) {
    return
}

ActionExportFailedApply(g, p) {
    return FSM_IDLE 

}
ActionExportFailedIO(g, p) {
    return
}

ActionCloseApply(g, p) {
    return FSM_CLOSING 

}
ActionCloseIO(g, p) {
    return
}

; ===================================================================================
; FSM Transition Table
; ===================================================================================
global G_FSM_TRANSITIONS := Map(
    FSM_LOADING, Map(
        EV_RENDER_DONE, {nextState: FSM_IDLE, guard: "ActionRenderDoneGuard", apply: "ActionRenderDoneApply", io: "ActionRenderDoneIO"},
        EV_RENDER_FAILED, {nextState: FSM_ERROR, guard: "ActionRenderFailedGuard", apply: "ActionRenderFailedApply", io: "ActionRenderFailedIO"}
    ),
    FSM_IDLE, Map(
        EV_DIRTY, {nextState: FSM_IDLE, apply: "ActionDirtyApply"},
        EV_CLEAN, {nextState: FSM_IDLE, apply: "ActionCleanApply"},
        EV_SAVE_CLICK, {nextState: FSM_SAVING, guard: "ActionSaveStartGuard", apply: "ActionSaveStartApply", io: "ActionSaveStartIO"},
        EV_FILE_CHANGED, {nextState: FSM_IDLE, guard: "ActionFileChangedGuard", apply: "ActionFileChangedApply"},
        EV_UPDATE_CLICK, {nextState: FSM_RELOADING, apply: "ActionUpdateClickApply", io: "ActionUpdateClickIO"},
        EV_REPROCESS_CLICK, {nextState: FSM_REPROCESSING, guard: "ActionReprocessStartGuard", apply: "ActionReprocessStartApply", io: "ActionReprocessStartIO"},
        EV_EXPORT_CLICK, {nextState: FSM_EXPORTING, guard: "ActionExportStartGuard", apply: "ActionExportStartApply", io: "ActionExportStartIO"},
        EV_CLOSE, {nextState: FSM_CLOSING, apply: "ActionCloseApply", io: "ActionCloseIO"}
    ),
    FSM_SAVING, Map(
        EV_SAVE_SUCCESS, {nextState: FSM_IDLE, apply: "ActionSaveSuccessApply"},
        EV_SAVE_FAILED, {nextState: FSM_IDLE, apply: "ActionSaveFailedApply"}
    ),
    FSM_RELOADING, Map(
        EV_RELOAD_DONE, {nextState: FSM_IDLE, apply: "ActionReloadDoneApply", io: "ActionReloadDoneIO"},
        EV_RELOAD_FAILED, {nextState: FSM_IDLE, apply: "ActionReloadFailedApply", io: "ActionReloadFailedIO"}
    ),
    FSM_REPROCESSING, Map(
        EV_REPROCESS_DONE, {nextState: FSM_IDLE, apply: "ActionReprocessDoneApply", io: "ActionReprocessDoneIO"},
        EV_REPROCESS_FAILED, {nextState: FSM_IDLE, apply: "ActionReprocessFailedApply", io: "ActionReprocessFailedIO"}
    ),
    FSM_EXPORTING, Map(
        EV_EXPORT_DONE, {nextState: FSM_IDLE, apply: "ActionExportDoneApply", io: "ActionExportDoneIO"},
        EV_EXPORT_FAILED, {nextState: FSM_IDLE, apply: "ActionExportFailedApply", io: "ActionExportFailedIO"}
    ),
    FSM_CLOSING, Map(
        EV_SAVE_CLICK, {nextState: FSM_SAVING, guard: "ActionSaveStartGuard", apply: "ActionSaveStartApply", io: "ActionSaveStartIO"}
    ),
    FSM_ERROR, Map()
)

FsmSelfCheck()
