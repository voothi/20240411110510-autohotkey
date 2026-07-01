
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


; ===================================================================================
; FSM Actions
; ===================================================================================

ActionRenderDoneGuard(guiObj, payload) {
    return true
}
ActionRenderDoneApply(guiObj, payload) {
    return FSM_IDLE
}
ActionRenderDoneIO(guiObj, payload) {
    try {
        if (WinGetMinMax(guiObj.Hwnd) == 1) {
            guiObj.wb.document.body.classList.add("maximized")
        } else {
            guiObj.wb.document.body.classList.remove("maximized")
        }
    } catch {
    }

    guiObj.wb.document.parentWindow.ahkCall := OnAhkCall.Bind(guiObj)
    guiObj.wvc.Visible := true
    try {
        WinRedraw(guiObj.wvc.Hwnd)
        WinRedraw(guiObj.Hwnd)
    } catch {
    }

    try {
        tsvPath := GetElementText(guiObj.wb.document.getElementById("tsv-path"))
        guiObj.TsvPath := tsvPath
        SplitPath(tsvPath, &fileName)
        guiObj.Title := "Kardenwort - " guiObj.Lang " (" guiObj.TextMode ") - " fileName

        try {
            guiObj.FsmMemory["IsProgressive"] := GetElementText(guiObj.wb.document.getElementById("progressive-loading")) == "true"
        } catch {
            guiObj.FsmMemory["IsProgressive"] := false
        }
        try {
            guiObj.FsmMemory["IsLazy"] := GetElementText(guiObj.wb.document.getElementById("lazy-processing")) == "true"
        } catch {
            guiObj.FsmMemory["IsLazy"] := false
        }

        if (FileExist(tsvPath)) {
            guiObj.FsmMemory["LastMTime"] := FileGetTime(tsvPath)
        } else {
            guiObj.FsmMemory["LastMTime"] := ""
        }

        if (G_FileWatcherIntervalMs > 0) {
            guiObj.TimerFn := WatchFile.Bind(guiObj)
            SetTimer(guiObj.TimerFn, G_FileWatcherIntervalMs)
        }
        if (guiObj.FsmMemory["IsLazy"]) {
            UpdateStatus(guiObj, "Lazy mode active. Select and Re-process.")
        } else {
            UpdateStatus(guiObj, "Analysis loaded successfully")
        }
    } catch as e {
        UpdateStatus(guiObj, "Metadata binding failed: " e.Message)
    }
}

ActionRenderFailedGuard(guiObj, payload) {
    return true
}
ActionRenderFailedApply(guiObj, payload) {
    return FSM_ERROR
}
ActionRenderFailedIO(guiObj, payload) {
    UpdateStatus(guiObj, "Analysis failed")
    MsgBox("Kardenwort Analysis failed:`n" payload, "Kardenwort Error", 16)
    global G_WindowCount
    G_WindowCount := Max(0, G_WindowCount - 1)
    guiObj.Destroy()
}

ActionDirtyApply(guiObj, payload) {
    guiObj.FsmMemory["IsDirty"] := true
    if (G_AutoSave) {
        guiObj.FsmMemory["AutoSavePending"] := true
    }
    return FSM_IDLE
}
ActionDirtyIO(guiObj, payload) {
    if (guiObj.FsmMemory["AutoSavePending"]) {
        guiObj.FsmMemory["AutoSavePending"] := false
        FsmDispatch(guiObj, EV_SAVE_CLICK)
    }
}

ActionCleanApply(guiObj, payload) {
    guiObj.FsmMemory["IsDirty"] := false
    return FSM_IDLE
}

ActionSaveStartGuard(guiObj, payload) {
    try {
        return guiObj.wb.document.parentWindow.isDirty()
    } catch {
        return false
    }
}
ActionSaveStartApply(guiObj, payload) {
    return FSM_SAVING
}
ActionSaveStartIO(guiObj, payload) {
    UpdateStatus(guiObj, "Saving...")
    try {
        deltasJSON := guiObj.wb.document.parentWindow.getDeltas()
    } catch as e {
        MsgBox("Failed to retrieve deltas from page: " e.Message, "Kardenwort Error", 16)
        FsmDispatch(guiObj, EV_SAVE_FAILED, e.Message)
        return
    }

    if (deltasJSON == "" || deltasJSON == "[]") {
        FsmDispatch(guiObj, EV_SAVE_SUCCESS)
        return
    }

    tmpTextFile := A_Temp "\karden_deltas_" guiObj.ZID "_" A_TickCount ".json"
    try {
        FileDelete(tmpTextFile)
    } catch {
    }
    try {
        FileAppend(deltasJSON, tmpTextFile, "UTF-8-RAW")
    } catch as e {
        MsgBox("Failed to write deltas to temp file: " e.Message, "Kardenwort Error", 16)
        FsmDispatch(guiObj, EV_SAVE_FAILED, e.Message)
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" edit-save --language ' guiObj.Lang ' --zid ' guiObj.ZID ' --tsv "' guiObj.TsvPath '" < "' tmpTextFile '"'
    try {
        exitCode := RunSilent(cmd, &outB64, &errJSON)
    } catch {
        exitCode := 1
        errJSON := "RunSilent failed"
    }
    
    try {
        FileDelete(tmpTextFile)
    } catch {
    }

    if (exitCode == 0) {
        FsmDispatch(guiObj, EV_SAVE_SUCCESS)
    } else {
        FsmDispatch(guiObj, EV_SAVE_FAILED, errJSON)
    }
}

ActionSaveSuccessApply(guiObj, payload) {
    try {
        guiObj.wb.document.parentWindow.clearDirty()
    } catch {
    }
    guiObj.FsmMemory["IsDirty"] := false
    try {
        if (FileExist(guiObj.TsvPath)) {
            guiObj.FsmMemory["LastMTime"] := FileGetTime(guiObj.TsvPath)
        }
    } catch {}

    if (guiObj.FsmMemory["PendingClose"]) {
        guiObj.FsmMemory["PendingClose"] := false
        return FSM_CLOSING
    } else if (guiObj.FsmMemory["PendingReprocess"]) {
        guiObj.FsmMemory["PendingReprocess"] := false
        return FSM_REPROCESSING
    } else if (guiObj.FsmMemory["PendingUpdate"]) {
        guiObj.FsmMemory["PendingUpdate"] := false
        return FSM_RELOADING
    }
    
    return FSM_IDLE
}
ActionSaveSuccessIO(guiObj, payload) {
    if (guiObj.FsmState == FSM_CLOSING) {
        ActionCloseIO(guiObj, "")
    } else if (guiObj.FsmState == FSM_REPROCESSING) {
        ActionReprocessStartIO(guiObj, "")
    } else if (guiObj.FsmState == FSM_RELOADING) {
        ActionUpdateClickIO(guiObj, "")
    } else {
        UpdateStatus(guiObj, "Edits saved successfully")
        UpdateButtonState(guiObj)
    }
}

ActionSaveFailedApply(guiObj, payload) {
    return FSM_IDLE
}
ActionSaveFailedIO(guiObj, payload) {
    UpdateStatus(guiObj, "Save failed")
    if (payload != "") {
        MsgBox("Save failed:`n" payload, "Kardenwort Error", 16)
    }
    UpdateButtonState(guiObj)
}

ActionFileChangedGuard(guiObj, payload) {
    if (payload == "") { return false }
    currentMTime := payload
    if (currentMTime == guiObj.FsmMemory["LastMTime"]) { return false }

    isAutoInjecting := guiObj.FsmMemory["IsProgressive"] || guiObj.FsmMemory["IsLazy"]
    if (isAutoInjecting) {
        updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
        if (FileExist(updateJsPath)) {
            jsMTime := FileGetTime(updateJsPath)
            if (Abs(DateDiff(currentMTime, jsMTime, "Seconds")) <= 10) {
                guiObj.FsmMemory["LastMTime"] := currentMTime
                guiObj.FsmMemory["AutoInjectRetries"] := 0
                UpdateStatus(guiObj, "Data injected automatically.")
                return false
            }
        }
        guiObj.FsmMemory["AutoInjectRetries"] += 1
        if (guiObj.FsmMemory["AutoInjectRetries"] < FSM_AUTO_INJECT_MAX_RETRIES) {
            return false
        }
        guiObj.FsmMemory["AutoInjectRetries"] := 0
    }

    if (G_AutoUpdate) {
        return true
    } else {
        guiObj.FsmMemory["PendingUpdate"] := true
        UpdateButtonState(guiObj)
        return false
    }
}
ActionFileChangedApply(guiObj, payload) {
    return FSM_RELOADING
}
ActionFileChangedIO(guiObj, payload) {
    ActionUpdateClickIO(guiObj, "")
}

ActionUpdateClickApply(guiObj, payload) {
    return FSM_RELOADING
}
ActionUpdateClickIO(guiObj, payload) {
    UpdateStatus(guiObj, "Reloading...")
    
    selectedRowsJSON := "[]"
    scrollY := 0
    try {
        selectedRowsJSON := guiObj.wb.document.parentWindow.getSelectedRows()
        scrollY := guiObj.wb.document.documentElement.scrollTop
        if (!scrollY) {
            scrollY := guiObj.wb.document.body.scrollTop
        }
    } catch {}

    exitCode := PerformReload(guiObj, &outB64, &errJSON)

    if (exitCode == 0) {
        payloadObj := {outB64: outB64, selectedRowsJSON: selectedRowsJSON, scrollY: scrollY}
        FsmDispatch(guiObj, EV_RELOAD_DONE, payloadObj)
    } else {
        FsmDispatch(guiObj, EV_RELOAD_FAILED, errJSON)
    }
}

ActionReloadDoneApply(guiObj, payload) {
    return FSM_IDLE
}
ActionReloadDoneIO(guiObj, payload) {
    try {
        hwnd := guiObj.Hwnd
    } catch {
        hwnd := 0
    }
    if (hwnd == 0 || !WinExist("ahk_id " hwnd) || !guiObj.HasProp("wb") || !IsObject(guiObj.wb)) { 
        return 
    }

    htmlContent := B64Decode(payload.outB64)
    tmpHtmlFile := A_Temp "\karden_view_" guiObj.ZID "_" A_TickCount ".html"
    FileAppend(htmlContent, tmpHtmlFile, "UTF-8-RAW")

    try {
        guiObj.wvc.Visible := false
        guiObj.wb.Navigate(tmpHtmlFile)
        while guiObj.wb.ReadyState != 4
            Sleep(10)
    } catch {
        try {
        FileDelete(tmpHtmlFile)
    } catch {
    }
        guiObj.wvc.Visible := true
        return
    }
    try {
        FileDelete(tmpHtmlFile)
    } catch {
    }

    try {
        ApplyZoom(guiObj.wb)
        if (WinGetMinMax(guiObj.Hwnd) == 1) {
            guiObj.wb.document.body.classList.add("maximized")
        } else {
            guiObj.wb.document.body.classList.remove("maximized")
        }
        guiObj.wb.document.parentWindow.ahkCall := OnAhkCall.Bind(guiObj)
        guiObj.wb.document.parentWindow.setSelectedRows(payload.selectedRowsJSON)
        if (payload.scrollY) {
            guiObj.wb.document.parentWindow.scrollTo(0, payload.scrollY)
        }
    } catch {}
    
    guiObj.wvc.Visible := true
    try {
        WinRedraw(guiObj.wvc.Hwnd)
        WinRedraw(guiObj.Hwnd)
    } catch {}

    try {
        guiObj.TsvPath := GetElementText(guiObj.wb.document.getElementById("tsv-path"))
        if (FileExist(guiObj.TsvPath)) {
            guiObj.FsmMemory["LastMTime"] := FileGetTime(guiObj.TsvPath)
        } else {
            guiObj.FsmMemory["LastMTime"] := ""
        }
        if (guiObj.FsmMemory["IsLazy"]) {
            UpdateStatus(guiObj, "Lazy mode active. Select and Re-process. (Reloaded)")
        } else {
            UpdateStatus(guiObj, "Analysis loaded successfully (Reloaded)")
        }
    } catch as e {
        UpdateStatus(guiObj, "Metadata binding failed (Reloaded): " e.Message)
    }
    guiObj.FsmMemory["PendingUpdate"] := false
    UpdateButtonState(guiObj)
}

ActionReloadFailedApply(guiObj, payload) {
    return FSM_IDLE
}
ActionReloadFailedIO(guiObj, payload) {
    UpdateStatus(guiObj, "Reload failed: render error")
    UpdateButtonState(guiObj)
}

ActionReprocessStartGuard(guiObj, payload) {
    try {
        jsonStr := guiObj.wb.document.parentWindow.getSelectedRows()
        if (jsonStr == "[]" || jsonStr == "") {
            MsgBox("Please select rows to re-process.", "Kardenwort", 48)
            UpdateStatus(guiObj, "Ready")
            return false
        }
        guiObj.FsmMemory["ReprocessSelection"] := jsonStr
        return true
    } catch {
        MsgBox("Failed to get selected rows.", "Kardenwort Error", 16)
        UpdateStatus(guiObj, "Ready")
        return false
    }
}
ActionReprocessStartApply(guiObj, payload) {
    if (guiObj.FsmMemory["IsDirty"]) {
        guiObj.FsmMemory["PendingReprocess"] := true
        return FSM_IDLE
    }
    return FSM_REPROCESSING
}
ActionReprocessStartIO(guiObj, payload) {
    if (guiObj.FsmMemory["PendingReprocess"]) {
        FsmDispatch(guiObj, EV_SAVE_CLICK)
        return
    }

    UpdateStatus(guiObj, "Preparing re-process...")
    jsonStr := guiObj.FsmMemory["ReprocessSelection"]
    guiObj.FsmMemory.Delete("ReprocessSelection")
    
    tsvPathStr := StrReplace(guiObj.TsvPath, "\", "\\")
    manifest := '{"selected_row_ids": ' jsonStr ', "zid": "' guiObj.ZID '", "tsv_path": "' tsvPathStr '"}'
    tmpManifestFile := A_Temp "\karden_manifest_" guiObj.ZID "_reproc.json"
    try {
        FileAppend(manifest, tmpManifestFile, "UTF-8-RAW")
    } catch as e {
        UpdateStatus(guiObj, "Manifest write failed")
        MsgBox("Failed to write temporary manifest file: " e.Message, "Kardenwort Error", 16)
        FsmDispatch(guiObj, EV_REPROCESS_FAILED, "")
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" reprocess --selection-manifest "' tmpManifestFile '" --language ' guiObj.Lang
    try {
        exitCode := RunSilent(cmd, &outStr, &errJSON)
    } catch {
        exitCode := 1
        errJSON := "RunSilent failed"
    }
    try {
        FileDelete(tmpManifestFile)
    } catch {
    }

    if (exitCode == 0) {
        FsmDispatch(guiObj, EV_REPROCESS_DONE, "")
    } else {
        FsmDispatch(guiObj, EV_REPROCESS_FAILED, errJSON)
    }
}

ActionReprocessDoneApply(guiObj, payload) {
    return FSM_IDLE
}
ActionReprocessDoneIO(guiObj, payload) {
    UpdateStatus(guiObj, "Re-processing started")
    UpdateButtonState(guiObj)
}

ActionReprocessFailedApply(guiObj, payload) {
    return FSM_IDLE
}
ActionReprocessFailedIO(guiObj, payload) {
    UpdateStatus(guiObj, "Re-process failed")
    if (payload != "") {
        try {
        FileAppend("Reprocess failed: " payload "`n", A_Desktop "\karden_error.txt")
    } catch {
    }
        MsgBox("Failed to start re-processing:`n" payload, "Kardenwort Error", 16)
    }
    UpdateButtonState(guiObj)
}

ActionExportStartGuard(guiObj, payload) {
    try {
        jsonStr := guiObj.wb.document.parentWindow.getSelectedRows()
        if (jsonStr == "[]" || jsonStr == "") {
            FsmDispatch(guiObj, EV_EXPORT_FAILED, "No rows selected")
            return false
        }
        guiObj.FsmMemory["ExportSelection"] := jsonStr
        return true
    } catch {
        FsmDispatch(guiObj, EV_EXPORT_FAILED, "Failed to get selected rows")
        return false
    }
}
ActionExportStartApply(guiObj, payload) {
    return FSM_EXPORTING
}
ActionExportStartIO(guiObj, payload) {
    UpdateStatus(guiObj, "Exporting favorites...")
    jsonStr := guiObj.FsmMemory["ExportSelection"]
    guiObj.FsmMemory.Delete("ExportSelection")

    tsvPathStr := StrReplace(guiObj.TsvPath, "\", "\\")
    manifest := '{"selected_row_ids": ' jsonStr ', "zid": "' guiObj.ZID '", "tsv_path": "' tsvPathStr '"}'
    tmpManifestFile := A_Temp "\karden_manifest_" guiObj.ZID "_send.json"
    try { FileAppend(manifest, tmpManifestFile, "UTF-8-RAW") } catch as e {
        FsmDispatch(guiObj, EV_EXPORT_FAILED, "Manifest write failed: " e.Message)
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" export-anki --selection-manifest "' tmpManifestFile '" --language ' guiObj.Lang
    try {
        exitCode := RunSilent(cmd, &outStr, &errJSON)
    } catch {
        exitCode := 1
        errJSON := "RunSilent failed"
    }
    try {
        FileDelete(tmpManifestFile)
    } catch {
    }

    if (exitCode == 0) {
        logPath := ""
        if RegExMatch(outStr, '"log":\s*"([^"]+)"', &match) {
            logPath := StrReplace(match[1], "\\", "\")
        }
        isAsync := InStr(outStr, '"import_started": true') > 0
        FsmDispatch(guiObj, EV_EXPORT_DONE, {isAsync: isAsync, logPath: logPath})
    } else {
        FsmDispatch(guiObj, EV_EXPORT_FAILED, errJSON)
    }
}

ActionExportDoneApply(guiObj, payload) {
    return FSM_IDLE
}
ActionExportDoneIO(guiObj, payload) {
    if (payload.isAsync) {
        if (G_ShowInfoWindows) {
            MsgBox("Anki import started in the background.`nMonitor log: " payload.logPath, "Kardenwort", "Iconi")
        }
    } else {
        if (G_ShowInfoWindows) {
            MsgBox("Favorites exported.", "Kardenwort", "Iconi")
        }
    }
    UpdateStatus(guiObj, "Ready")
    UpdateButtonState(guiObj)
}

ActionExportFailedApply(guiObj, payload) {
    return FSM_IDLE
}
ActionExportFailedIO(guiObj, payload) {
    UpdateStatus(guiObj, "Export failed")
    if (payload != "") {
        try {
        FileAppend("Export failed: " payload "`n", A_Desktop "\karden_error.txt")
    } catch {
    }
        MsgBox("Failed to export favorites:`n" payload, "Kardenwort Error", 16)
    }
    UpdateButtonState(guiObj)
}

ActionCloseApply(guiObj, payload) {
    if (guiObj.FsmMemory["IsDirty"]) {
        res := MsgBox("You have unsaved edits. Save changes before closing?", "Kardenwort", "YesNoCancel Icon!")
        if (res == "Cancel") {
            return FSM_IDLE
        } else if (res == "Yes") {
            guiObj.FsmMemory["PendingClose"] := true
            return FSM_CLOSING
        }
    }
    return FSM_CLOSING
}
ActionCloseIO(guiObj, payload) {
    if (guiObj.FsmMemory["PendingClose"]) {
        FsmDispatch(guiObj, EV_SAVE_CLICK)
        return
    }

    if (guiObj.HasOwnProp("TimerFn")) {
        SetTimer(guiObj.TimerFn, 0)
    }
    if (guiObj.HasOwnProp("TsvPath") && guiObj.TsvPath != "") {
        updateJsPath := StrReplace(guiObj.TsvPath, ".tsv", ".update.js")
        try {
            if FileExist(updateJsPath) {
                FileDelete(updateJsPath)
            }
        } catch {}
    }
    guiObj.wb := ""
    guiObj.Destroy()
    global G_WindowCount
    G_WindowCount := Max(0, G_WindowCount - 1)
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
        EV_DIRTY, {nextState: FSM_IDLE, apply: "ActionDirtyApply", io: "ActionDirtyIO"},
        EV_CLEAN, {nextState: FSM_IDLE, apply: "ActionCleanApply"},
        EV_SAVE_CLICK, {nextState: FSM_SAVING, guard: "ActionSaveStartGuard", apply: "ActionSaveStartApply", io: "ActionSaveStartIO"},
        EV_FILE_CHANGED, {nextState: FSM_IDLE, guard: "ActionFileChangedGuard", apply: "ActionFileChangedApply", io: "ActionFileChangedIO"},
        EV_UPDATE_CLICK, {nextState: FSM_RELOADING, apply: "ActionUpdateClickApply", io: "ActionUpdateClickIO"},
        EV_REPROCESS_CLICK, {nextState: FSM_REPROCESSING, guard: "ActionReprocessStartGuard", apply: "ActionReprocessStartApply", io: "ActionReprocessStartIO"},
        EV_EXPORT_CLICK, {nextState: FSM_EXPORTING, guard: "ActionExportStartGuard", apply: "ActionExportStartApply", io: "ActionExportStartIO"},
        EV_CLOSE, {nextState: FSM_CLOSING, apply: "ActionCloseApply", io: "ActionCloseIO"}
    ),
    FSM_SAVING, Map(
        EV_SAVE_SUCCESS, {nextState: FSM_IDLE, apply: "ActionSaveSuccessApply", io: "ActionSaveSuccessIO"},
        EV_SAVE_FAILED, {nextState: FSM_IDLE, apply: "ActionSaveFailedApply", io: "ActionSaveFailedIO"}
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
