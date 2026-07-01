#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\Lib\ClipboardUtil.ahk
#Include ..\Lib\B64Util.ahk

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

global G_FileWatcherIntervalMs := 0
global G_AutoSave := 0
global G_DeskPythonPath := ""
global G_DeskScriptPath := ""
global G_AutoUpdate := 0
global G_ShowInfoWindows := 0

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
    validStates := Map(FSM_LOADING, 1, FSM_IDLE, 1, FSM_SAVING, 1, FSM_RELOADING, 1, FSM_REPROCESSING, 1, FSM_EXPORTING,
        1, FSM_CLOSING, 1, FSM_ERROR, 1)
    validEvents := Map(EV_RENDER_DONE, 1, EV_RENDER_FAILED, 1, EV_DIRTY, 1, EV_CLEAN, 1, EV_SAVE_CLICK, 1,
        EV_SAVE_SUCCESS, 1, EV_SAVE_FAILED, 1, EV_FILE_CHANGED, 1, EV_UPDATE_CLICK, 1, EV_RELOAD_DONE, 1,
        EV_RELOAD_FAILED, 1, EV_REPROCESS_CLICK, 1, EV_REPROCESS_DONE, 1, EV_REPROCESS_FAILED, 1, EV_EXPORT_CLICK, 1,
        EV_EXPORT_DONE, 1, EV_EXPORT_FAILED, 1, EV_CLOSE, 1)

    for state, events in G_FSM_TRANSITIONS {
        if (!validStates.Has(state)) {
            MsgBox("FSM Self-Check Failed: Invalid state '" state "' in transition table.", "Kardenwort FSM Error", 16)
            ExitApp()
        }
        for ev, trans in events {
            if (!validEvents.Has(ev)) {
                MsgBox("FSM Self-Check Failed: Invalid event '" ev "' in transition table.", "Kardenwort FSM Error", 16
                )
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
    isMax := false
    try {
        isMax := (WinGetMinMax(guiObj.Hwnd) == 1)
    } catch {
    }
    try {
        if (isMax) {
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
            guiObj.FsmMemory["IsProgressive"] := GetElementText(guiObj.wb.document.getElementById("progressive-loading"
            )) == "true"
        } catch {
            guiObj.FsmMemory["IsProgressive"] := false
        }
        try {
            guiObj.FsmMemory["IsLazy"] := GetElementText(guiObj.wb.document.getElementById("lazy-processing")) ==
            "true"
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

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" edit-save --language ' guiObj.Lang ' --zid ' guiObj.ZID ' --tsv "' guiObj
        .TsvPath '" < "' tmpTextFile '"'
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
    if (FileExist(guiObj.TsvPath)) {
        try {
            guiObj.FsmMemory["LastMTime"] := FileGetTime(guiObj.TsvPath)
        } catch {
        }
    }

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
    if (payload == "") {
        return false
    }
    currentMTime := payload
    if (currentMTime == guiObj.FsmMemory["LastMTime"]) {
        return false
    }

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
    } catch {
    }
    if (!scrollY) {
        try {
            scrollY := guiObj.wb.document.body.scrollTop
        } catch {
        }
    }

    exitCode := PerformReload(guiObj, &outB64, &errJSON)

    if (exitCode == 0) {
        payloadObj := { outB64: outB64, selectedRowsJSON: selectedRowsJSON, scrollY: scrollY }
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
    } catch {
    }
    isMax := false
    try {
        isMax := (WinGetMinMax(guiObj.Hwnd) == 1)
    } catch {
    }
    try {
        if (isMax) {
            guiObj.wb.document.body.classList.add("maximized")
        } else {
            guiObj.wb.document.body.classList.remove("maximized")
        }
    } catch {
    }
    try {
        guiObj.wb.document.parentWindow.ahkCall := OnAhkCall.Bind(guiObj)
        guiObj.wb.document.parentWindow.setSelectedRows(payload.selectedRowsJSON)
    } catch {
    }
    if (payload.scrollY) {
        try {
            guiObj.wb.document.parentWindow.scrollTo(0, payload.scrollY)
        } catch {
        }
    }

    guiObj.wvc.Visible := true
    try {
        WinRedraw(guiObj.wvc.Hwnd)
        WinRedraw(guiObj.Hwnd)
    } catch {
    }

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

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" reprocess --selection-manifest "' tmpManifestFile '" --language ' guiObj
        .Lang
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
    try {
        FileAppend(manifest, tmpManifestFile, "UTF-8-RAW")
    } catch as e {
        FsmDispatch(guiObj, EV_EXPORT_FAILED, "Manifest write failed: " e.Message)
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" export-anki --selection-manifest "' tmpManifestFile '" --language ' guiObj
        .Lang
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
        FsmDispatch(guiObj, EV_EXPORT_DONE, { isAsync: isAsync, logPath: logPath })
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
        if FileExist(updateJsPath) {
            try {
                FileDelete(updateJsPath)
            } catch {
            }
        }
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
        EV_RENDER_DONE, { nextState: FSM_IDLE, guard: "ActionRenderDoneGuard", apply: "ActionRenderDoneApply", io: "ActionRenderDoneIO" },
        EV_RENDER_FAILED, { nextState: FSM_ERROR, guard: "ActionRenderFailedGuard", apply: "ActionRenderFailedApply",
            io: "ActionRenderFailedIO" }
    ),
    FSM_IDLE, Map(
        EV_DIRTY, { nextState: FSM_IDLE, apply: "ActionDirtyApply", io: "ActionDirtyIO" },
        EV_CLEAN, { nextState: FSM_IDLE, apply: "ActionCleanApply" },
        EV_SAVE_CLICK, { nextState: FSM_SAVING, guard: "ActionSaveStartGuard", apply: "ActionSaveStartApply", io: "ActionSaveStartIO" },
        EV_FILE_CHANGED, { nextState: FSM_IDLE, guard: "ActionFileChangedGuard", apply: "ActionFileChangedApply", io: "ActionFileChangedIO" },
        EV_UPDATE_CLICK, { nextState: FSM_RELOADING, apply: "ActionUpdateClickApply", io: "ActionUpdateClickIO" },
        EV_REPROCESS_CLICK, { nextState: FSM_REPROCESSING, guard: "ActionReprocessStartGuard", apply: "ActionReprocessStartApply",
            io: "ActionReprocessStartIO" },
        EV_EXPORT_CLICK, { nextState: FSM_EXPORTING, guard: "ActionExportStartGuard", apply: "ActionExportStartApply",
            io: "ActionExportStartIO" },
        EV_CLOSE, { nextState: FSM_CLOSING, apply: "ActionCloseApply", io: "ActionCloseIO" }
    ),
    FSM_SAVING, Map(
        EV_SAVE_SUCCESS, { nextState: FSM_IDLE, apply: "ActionSaveSuccessApply", io: "ActionSaveSuccessIO" },
        EV_SAVE_FAILED, { nextState: FSM_IDLE, apply: "ActionSaveFailedApply", io: "ActionSaveFailedIO" }
    ),
    FSM_RELOADING, Map(
        EV_RELOAD_DONE, { nextState: FSM_IDLE, apply: "ActionReloadDoneApply", io: "ActionReloadDoneIO" },
        EV_RELOAD_FAILED, { nextState: FSM_IDLE, apply: "ActionReloadFailedApply", io: "ActionReloadFailedIO" }
    ),
    FSM_REPROCESSING, Map(
        EV_REPROCESS_DONE, { nextState: FSM_IDLE, apply: "ActionReprocessDoneApply", io: "ActionReprocessDoneIO" },
        EV_REPROCESS_FAILED, { nextState: FSM_IDLE, apply: "ActionReprocessFailedApply", io: "ActionReprocessFailedIO" }
    ),
    FSM_EXPORTING, Map(
        EV_EXPORT_DONE, { nextState: FSM_IDLE, apply: "ActionExportDoneApply", io: "ActionExportDoneIO" },
        EV_EXPORT_FAILED, { nextState: FSM_IDLE, apply: "ActionExportFailedApply", io: "ActionExportFailedIO" }
    ),
    FSM_CLOSING, Map(
        EV_SAVE_CLICK, { nextState: FSM_SAVING, guard: "ActionSaveStartGuard", apply: "ActionSaveStartApply", io: "ActionSaveStartIO" }
    ),
    FSM_ERROR, Map()
)

FsmSelfCheck()
; ===================================================================================
; Configuration & Globals
; ===================================================================================
global G_DeskPythonPath := ""
global G_DeskScriptPath := ""
global G_DefaultLanguage := "en"
global G_CurrentLang := "en"
global G_FileWatcherIntervalMs := 1000
global G_AutoUpdate := 0
global G_AutoSave := 0
global G_MultiTapTimeout := 300
global G_TapSingleMode := "single"
global G_TapDoubleMode := "multi"
global G_OrdinaryColor := "#ffd700"
global G_PairedColor := "#9370db"
global G_DefaultZoom := "100"
global G_Theme := "dark"
global G_GuiBgColor := "0D0F12"
global G_GuiTextColor := "c0xE3E6EB"
global G_DwmDark := 1
global G_ShowInfoWindows := 1

global G_PressCount := 0
global G_CapturedText := ""
global G_WindowCount := 0
global G_CascadeIndex := 0
global G_BaseX := ""
global G_BaseY := ""
global G_CurrentHIcon := 0
global langCodes := []
global langNames := Map()
global langInfo := Map()

LoadConfig() {
    configPath := A_ScriptDir "\config.ini"
    if !FileExist(configPath) {
        MsgBox("Configuration file not found: " configPath, "Kardenwort Error", 16)
        ExitApp()
    }

    global G_DeskPythonPath := IniRead(configPath, "Paths", "DeskPythonPath", "")
    global G_DeskScriptPath := IniRead(configPath, "Paths", "DeskScriptPath", "")
    global G_DefaultLanguage := IniRead(configPath, "Settings", "DefaultLanguage", "en")
    global G_CurrentLang := IniRead(configPath, "Settings", "DefaultLanguage", "en")
    global G_FileWatcherIntervalMs := IniRead(configPath, "Settings", "FileWatcherIntervalMs", 1000)
    global G_AutoUpdate := IniRead(configPath, "Settings", "AutoUpdate", 0)
    global G_AutoSave := IniRead(configPath, "Settings", "auto_save_on_edit", 0)
    global G_ShowInfoWindows := IniRead(configPath, "Settings", "ShowInfoWindows", 1)
    global G_MultiTapTimeout := IniRead(configPath, "Settings", "MultiTapTimeout", 300)
    global G_TapSingleMode := IniRead(configPath, "Hotkey", "TapSingleMode", "single")
    global G_TapDoubleMode := IniRead(configPath, "Hotkey", "TapDoubleMode", "multi")
    global G_OrdinaryColor := IniRead(configPath, "Highlight", "OrdinaryColor", "#ffd700")
    global G_PairedColor := IniRead(configPath, "Highlight", "PairedColor", "#9370db")
    global G_DefaultZoom := IniRead(configPath, "Settings", "DefaultZoom", "100")
    global G_Theme := StrLower(IniRead(configPath, "Settings", "Theme", "dark"))
    global G_GuiBgColor := (G_Theme == "light" || G_Theme == "white") ? "F6F8FA" : "0D0F12"
    global G_GuiTextColor := (G_Theme == "light" || G_Theme == "white") ? "c0x24292F" : "c0xE3E6EB"
    global G_DwmDark := (G_Theme == "light" || G_Theme == "white") ? 0 : 1

    if (G_DeskPythonPath == "" || !FileExist(G_DeskPythonPath)) {
        MsgBox("Python interpreter not found: " G_DeskPythonPath, "Kardenwort Error", 16)
        ExitApp()
    }
    if (G_DeskScriptPath == "" || !FileExist(G_DeskScriptPath)) {
        MsgBox("Desk script not found: " G_DeskScriptPath, "Kardenwort Error", 16)
        ExitApp()
    }
}

InitializeTrayMenu() {
    global langCodes, langNames, langInfo
    configPath := A_ScriptDir "\config.ini"

    defaultLangInfo := Map(
        "en", { text: "En", bg: 0x008000, fg: 0xFFFFFF },
        "de", { text: "De", bg: 0x8B0000, fg: 0xFFFFFF },
        "ru", { text: "Ru", bg: 0x00008B, fg: 0xFFFFFF },
        "uk", { text: "Uk", bg: 0xFFD700, fg: 0x000000 }
    )

    try {
        langSection := IniRead(configPath, "Languages")
        for line in StrSplit(langSection, "`n") {
            if (line == "" || InStr(line, ";") == 1)
                continue
            parts := StrSplit(line, "=")
            code := Trim(parts[1])
            valStr := Trim(parts[2])

            if InStr(valStr, ",") {
                vals := StrSplit(valStr, ",")
                langNames[code] := Trim(vals[1])
                langInfo[code] := {
                    text: vals.Length >= 2 ? Trim(vals[2]) : StrUpper(code),
                    bg: vals.Length >= 3 ? Number(Trim(vals[3])) : (defaultLangInfo.Has(code) ? defaultLangInfo[code].bg :
                        0x808080),
                    fg: vals.Length >= 4 ? Number(Trim(vals[4])) : (defaultLangInfo.Has(code) ? defaultLangInfo[code].fg :
                        0xFFFFFF)
                }
            } else {
                langNames[code] := valStr
                langInfo[code] := defaultLangInfo.Has(code) ? defaultLangInfo[code] : { text: StrUpper(code), bg: 0x808080,
                    fg: 0xFFFFFF }
            }

            langCodes.Push(code)
        }
    } catch Any as e {
        MsgBox("Error parsing [Languages] section in config.ini:`n" e.Message, "Config Error", "Icon!")
    }

    UpdateTrayMenu()
    UpdateTrayIcon()
}

UpdateTrayMenu() {
    global G_CurrentLang, langNames, langCodes
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Current Language: " . G_CurrentLang, (*) => 0)
    A_TrayMenu.Disable("1&")
    A_TrayMenu.Add() ; Separator

    for code in langCodes {
        name := langNames[code]
        A_TrayMenu.Add(name " (" code ")", ((c, *) => SetLanguage(c)).Bind(code))
    }

    A_TrayMenu.Add() ; Separator
    A_TrayMenu.AddStandard()
}

UpdateTrayIcon() {
    global G_CurrentLang, G_CurrentHIcon, langInfo

    info := { text: StrUpper(G_CurrentLang), bg: 0x808080, fg: 0xFFFFFF }
    if langInfo.Has(G_CurrentLang) {
        info := langInfo[G_CurrentLang]
    }

    newHIcon := CreateIconFromText(info.text, info.bg, info.fg)
    if (newHIcon) {
        TraySetIcon("HICON:" . newHIcon)
        if (G_CurrentHIcon) {
            DllCall("DestroyIcon", "Ptr", G_CurrentHIcon)
        }
        G_CurrentHIcon := newHIcon
    }
}

CreateIconFromText(text, bgColor, textColor) {
    s := 16
    hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
    hMemDC := DllCall("CreateCompatibleDC", "Ptr", hDC, "Ptr")
    hBitmap := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", s, "Int", s, "Ptr")
    hOldBitmap := DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hBitmap, "Ptr")

    ; Draw background
    rect := Buffer(16, 0)
    NumPut("Int", 0, "Int", 0, "Int", s, "Int", s, rect)
    hBrush := DllCall("CreateSolidBrush", "UInt", bgColor, "Ptr")
    DllCall("FillRect", "Ptr", hMemDC, "Ptr", rect, "Ptr", hBrush)
    DllCall("DeleteObject", "Ptr", hBrush)

    ; Draw text
    DllCall("SetTextColor", "Ptr", hMemDC, "UInt", textColor)
    DllCall("SetBkMode", "Ptr", hMemDC, "Int", 1) ; Transparent

    hFont := DllCall("CreateFont", "Int", -11, "Int", 0, "Int", 0, "Int", 0, "Int", 700, "UInt", 0, "UInt", 0, "UInt",
        0, "UInt", 0, "UInt", 3, "UInt", 2, "UInt", 1, "UInt", 34, "Str", "Arial Narrow", "Ptr")
    hOldFont := DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hFont, "Ptr")
    DllCall("DrawText", "Ptr", hMemDC, "Str", text, "Int", -1, "Ptr", rect, "UInt", 0x25)

    ; Create Icon
    iconInfo := Buffer(A_PtrSize == 8 ? 32 : 20, 0)
    NumPut("Int", 1, iconInfo, 0) ; fIcon = true
    hMask := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", s, "Int", s, "Ptr")
    NumPut("Ptr", hMask, iconInfo, A_PtrSize == 8 ? 16 : 12)
    NumPut("Ptr", hBitmap, iconInfo, A_PtrSize == 8 ? 24 : 16)

    hIcon := DllCall("CreateIconIndirect", "Ptr", iconInfo, "Ptr")

    ; Cleanup
    DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hOldBitmap)
    DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hOldFont)
    DllCall("DeleteObject", "Ptr", hMask)
    DllCall("DeleteObject", "Ptr", hBitmap)
    DllCall("DeleteObject", "Ptr", hFont)
    DllCall("DeleteDC", "Ptr", hMemDC)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)

    return hIcon
}

SetLanguage(lang) {
    global G_CurrentLang := lang
    UpdateTrayMenu()
    UpdateTrayIcon()
}

CycleLanguage() {
    global G_CurrentLang, langCodes
    currentIndex := 0
    for i, code in langCodes {
        if (code == G_CurrentLang) {
            currentIndex := i
            break
        }
    }

    nextIndex := currentIndex + 1
    if (nextIndex > langCodes.Length)
        nextIndex := 1

    SetLanguage(langCodes[nextIndex])
}

LaunchRestore(filePath) {
    if !FileExist(filePath) {
        MsgBox("Restore target file not found: " filePath, "Kardenwort Error", 16)
        ExitApp()
    }

    SplitPath(filePath, &fileName, &fileDir)
    RegExMatch(fileName, "^(\d{14})", &mZid)
    if (!mZid) {
        MsgBox("No valid 14-digit ZID prefix in restore file: " fileName, "Kardenwort Error", 16)
        ExitApp()
    }
    ZID := mZid[1]

    siblingTxt := ""
    txtPattern := fileDir "\" ZID "-*.txt"
    loop files, txtPattern {
        siblingTxt := A_LoopFilePath
        break
    }
    if (siblingTxt == "") {
        if (SubStr(filePath, -4) == ".txt") {
            siblingTxt := filePath
        } else {
            altPath := RegExReplace(filePath, "\.tsv$", ".txt")
            if FileExist(altPath) {
                siblingTxt := altPath
            }
        }
    }

    sourceText := ""
    if (siblingTxt != "" && FileExist(siblingTxt)) {
        sourceText := FileRead(siblingTxt, "UTF-8")
    } else {
        MsgBox("Warning: Sibling source text file not found.", "Kardenwort Warning", 48)
    }

    lang := G_DefaultLanguage
    foundTsv := ""
    tsvPattern := fileDir "\" ZID "-*.tsv"
    loop files, tsvPattern {
        foundTsv := A_LoopFileName
        break
    }
    if (foundTsv != "") {
        RegExMatch(foundTsv, "\.([a-z]{2})\.tsv$", &mLang)
        if (mLang) {
            lang := mLang[1]
        }
    } else {
        RegExMatch(fileName, "\.([a-z]{2})\.(tsv|txt|srt)$", &mLang)
        if (mLang) {
            lang := mLang[1]
        }
    }

    global G_CurrentLang := lang
    UpdateTrayMenu()
    UpdateTrayIcon()

    inferredMode := "single"
    if (InStr(sourceText, "`n") || InStr(sourceText, "`r")) {
        inferredMode := "multi"
    }

    LaunchKardenwortWindow(sourceText, inferredMode, ZID)
}

LaunchDesk(filePath, textMode) {
    if !FileExist(filePath) {
        MsgBox("File not found: " filePath, "Kardenwort Error", 16)
        ExitApp()
    }

    sourceText := FileRead(filePath, "UTF-8")

    SplitPath(filePath, &fileName)
    lang := G_DefaultLanguage
    RegExMatch(fileName, "\.([a-z]{2})\.(txt|srt)$", &mLang)
    if (mLang) {
        lang := mLang[1]
    }

    global G_CurrentLang := lang
    UpdateTrayMenu()
    UpdateTrayIcon()

    LaunchKardenwortWindow(sourceText, textMode)
}

; Initialize configuration and tray menu
LoadConfig()
InitializeTrayMenu()

; Check startup arguments
if (A_Args.Length > 0) {
    mode := ""
    filePath := ""
    textMode := "multi"

    i := 1
    while (i <= A_Args.Length) {
        arg := A_Args[i]
        if (arg == "--restore") {
            mode := "restore"
            filePath := A_Args[i + 1]
            i += 2
        } else if (arg == "--desk") {
            mode := "desk"
            filePath := A_Args[i + 1]
            i += 2
        } else if (arg == "--text-mode") {
            textMode := A_Args[i + 1]
            i += 2
        } else {
            i += 1
        }
    }

    if (mode == "restore") {
        LaunchRestore(filePath)
    } else if (mode == "desk") {
        LaunchDesk(filePath, textMode)
    }
}

; ===================================================================================
; Execution Utilities
; ===================================================================================
RunSilent(cmd, &stdout := "", &stderr := "") {
    tmpOut := A_Temp "\karden_out_" A_Now "_" A_TickCount ".txt"
    tmpErr := A_Temp "\karden_err_" A_Now "_" A_TickCount ".txt"

    fullCmd := 'cmd.exe /c "' cmd ' > "' tmpOut '" 2> "' tmpErr '"'

    shell := ComObject("WScript.Shell")
    exitCode := shell.Run(fullCmd, 0, true)

    if FileExist(tmpOut) {
        try {
            stdout := FileRead(tmpOut, "UTF-8")
        } catch {
            stdout := ""
        }
        try {
            FileDelete(tmpOut)
        } catch {
        }
    }
    if FileExist(tmpErr) {
        try {
            stderr := FileRead(tmpErr, "UTF-8")
        } catch {
            stderr := ""
        }
        try {
            FileDelete(tmpErr)
        } catch {
        }
    }
    return exitCode
}

GetCascadeCoords(&x, &y) {
    global G_CascadeIndex
    x := 50 + Mod(G_CascadeIndex, 15) * 30
    y := 50 + Mod(G_CascadeIndex, 15) * 30
}

ApplyZoom(wb) {
    global G_DefaultZoom
    try {
        if (G_DefaultZoom != "100" && G_DefaultZoom != "") {
            wb.ExecWB(63, 2, Integer(G_DefaultZoom), 0)
        }
    }
}

; ===================================================================================
; GUI & Watcher Implementation
; ===================================================================================
LaunchKardenwortWindow(sourceText, textMode, presetZID := "") {
    ZID := presetZID != "" ? presetZID : A_Now
    lang := G_CurrentLang

    guiTitle := "Kardenwort - " lang " (" textMode ")"

    ; Create GUI
    MyGui := Gui("+Resize +MinSize400x300", guiTitle)
    MyGui.BackColor := G_GuiBgColor
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 20, "Ptr*", G_DwmDark, "UInt", 4)
    MyGui.OnEvent("Close", GuiClose)
    MyGui.OnEvent("Size", GuiSize)
    MyGui.OnEvent("Escape", GuiEscape)

    ; ActiveX Explorer
    wvc := MyGui.Add("ActiveX", "x10 y10 w800 h600 +Hidden -E0x200", "Shell.Explorer")
    wb := wvc.Value

    ; Native Footer Buttons
    SaveBtn := MyGui.Add("Text", "x15 y615 w110 h30 Center +Border +0x200 " G_GuiTextColor " Disabled", "Save (Ctrl+S)"
    )
    UpdateBtn := MyGui.Add("Text", "x135 y615 w110 h30 Center +Border +0x200 +Hidden " G_GuiTextColor, "⟳ Update")
    ReprocBtn := MyGui.Add("Text", "x255 y615 w110 h30 Center +Border +0x200 " G_GuiTextColor, "Re-process")
    DeleteBtn := MyGui.Add("Text", "x375 y615 w110 h30 Center +Border +0x200 " G_GuiTextColor, "Delete")
    SendBtn := MyGui.Add("Text", "x495 y615 w120 h30 Center +Border +0x200 " G_GuiTextColor, "Send to Anki")
    StatusTxt := MyGui.Add("Text", "x625 y615 w300 h30 +0x200 vStatusTxt", "Ready")
    StatusTxt.SetFont(G_GuiTextColor)

    ; Store references on GUI object
    MyGui.wb := wb
    MyGui.wvc := wvc
    MyGui.SaveBtn := SaveBtn
    MyGui.UpdateBtn := UpdateBtn
    MyGui.SendBtn := SendBtn
    MyGui.DeleteBtn := DeleteBtn
    MyGui.ReprocBtn := ReprocBtn
    MyGui.StatusTxt := StatusTxt
    MyGui.ZID := ZID
    MyGui.Lang := lang
    MyGui.TextMode := textMode
    MyGui.SourceText := sourceText
    MyGui.TsvPath := ""
    FsmInit(MyGui)

    SaveBtn.OnEvent("Click", OnSaveClick.Bind(MyGui))
    UpdateBtn.OnEvent("Click", OnUpdateClick.Bind(MyGui))
    SendBtn.OnEvent("Click", OnSendToAnkiClick.Bind(MyGui))
    DeleteBtn.OnEvent("Click", OnDeleteClick.Bind(MyGui))
    ReprocBtn.OnEvent("Click", OnReprocessClick.Bind(MyGui))

    configPath := A_ScriptDir "\config.ini"
    initX := Trim(StrSplit(IniRead(configPath, "Window", "X", ""), ";")[1])
    initY := Trim(StrSplit(IniRead(configPath, "Window", "Y", ""), ";")[1])
    initW := Trim(StrSplit(IniRead(configPath, "Window", "Width", "1143"), ";")[1])
    initH := Trim(StrSplit(IniRead(configPath, "Window", "Height", "957"), ";")[1])

    global G_WindowCount, G_CascadeIndex, G_BaseX, G_BaseY
    if (G_WindowCount == 0) {
        G_CascadeIndex := 0
        if (initX == "" || initY == "") {
            GetCascadeCoords(&x, &y)
            showStr := "x" x " y" y " w" initW " h" initH
        } else {
            showStr := "x" initX " y" initY " w" initW " h" initH
        }
    } else {
        if (G_BaseX !== "" && G_BaseY !== "") {
            cascadeOffset := Mod(G_CascadeIndex, 15) * 30
            x := G_BaseX + cascadeOffset
            y := G_BaseY + cascadeOffset
            showStr := "x" x " y" y " w" initW " h" initH
        } else {
            GetCascadeCoords(&x, &y)
            showStr := "x" x " y" y " w" initW " h" initH
        }
    }

    MyGui.Show(showStr)
    MyGui.GetClientPos(, , &clientWidth, &clientHeight)
    GuiSize(MyGui, 0, clientWidth, clientHeight)
    if (G_WindowCount == 0) {
        MyGui.GetPos(&outX, &outY)
        G_BaseX := outX
        G_BaseY := outY
    }
    G_WindowCount += 1
    G_CascadeIndex += 1

    ; Fetch HTML from Python core
    UpdateStatus(MyGui, "Invoking backend analysis...")

    tmpTextFile := A_Temp "\karden_input_" ZID "_" A_TickCount ".txt"
    try {
        FileDelete(tmpTextFile)
    } catch {
    }
    try {
        FileAppend(sourceText, tmpTextFile, "UTF-8-RAW")
    } catch as e {
        UpdateStatus(MyGui, "Input write failed")
        MsgBox("Failed to write temporary text input:`n" e.Message, "Kardenwort Error", 16)
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" render --language ' lang ' --zid ' ZID ' --text-mode ' textMode ' --zoom ' G_DefaultZoom ' --theme ' G_Theme ' < "' tmpTextFile '"'
    exitCode := RunSilent(cmd, &outB64, &errJSON)
    try {
        FileDelete(tmpTextFile)
    } catch {
    }

    if (exitCode != 0) {
        FsmDispatch(MyGui, EV_RENDER_FAILED, errJSON)
    } else {
        FsmDispatch(MyGui, EV_RENDER_DONE, { outB64: outB64 })
    }
}

OnAhkCall(guiObj, action, value) {
    if (action == "dirty") {
        if (value == "true") {
            FsmDispatch(guiObj, EV_DIRTY)
        } else {
            FsmDispatch(guiObj, EV_CLEAN)
        }
    }
}

UpdateButtonState(guiObj) {
    if (!guiObj.HasProp("FsmState") || !guiObj.HasProp("FsmMemory")) {
        return
    }

    if (guiObj.FsmState == FSM_RELOADING || guiObj.FsmState == FSM_REPROCESSING || guiObj.FsmState == FSM_LOADING ||
        guiObj.FsmState == FSM_SAVING || guiObj.FsmState == FSM_CLOSING) {
        guiObj.UpdateBtn.Visible := false
        guiObj.SaveBtn.Enabled := false
        guiObj.SendBtn.Enabled := false
        guiObj.DeleteBtn.Enabled := false
        guiObj.ReprocBtn.Enabled := false
        return
    }

    if (guiObj.FsmState == FSM_EXPORTING) {
        guiObj.UpdateBtn.Visible := false
        guiObj.SaveBtn.Enabled := false
        guiObj.SendBtn.Enabled := false
        guiObj.DeleteBtn.Enabled := false
        guiObj.ReprocBtn.Enabled := false
        UpdateStatus(guiObj, "Exporting favorites...")
        return
    }

    isDirty := false
    if (guiObj.FsmMemory.Has("IsDirty")) {
        isDirty := guiObj.FsmMemory["IsDirty"]
    }
    pending := false
    if (guiObj.FsmMemory.Has("PendingUpdate")) {
        pending := guiObj.FsmMemory["PendingUpdate"]
    }

    guiObj.SaveBtn.Enabled := isDirty
    guiObj.SendBtn.Enabled := true
    guiObj.DeleteBtn.Enabled := true
    guiObj.ReprocBtn.Enabled := true

    if (pending) {
        guiObj.UpdateBtn.Visible := true
        guiObj.UpdateBtn.Enabled := true
    } else {
        guiObj.UpdateBtn.Visible := false
    }

    if (isDirty && pending) {
        UpdateStatus(guiObj, "Unsaved edits + update ready")
    } else if (isDirty && !pending) {
        UpdateStatus(guiObj, "Unsaved edits")
    } else if (!isDirty && pending) {
        UpdateStatus(guiObj, "Data ready. Click ⟳ to update.")
    }
}

OnUpdateClick(guiObj, *) {
    FsmDispatch(guiObj, EV_UPDATE_CLICK)
}

OnSaveClick(guiObj, *) {
    FsmDispatch(guiObj, EV_SAVE_CLICK)
}

OnSendToAnkiClick(guiObj, *) {
    FsmDispatch(guiObj, EV_EXPORT_CLICK)
}

OnDeleteClick(guiObj, *) {
    try {
        guiObj.wb.document.parentWindow.deleteSelectedRows()
        FsmDispatch(guiObj, EV_DIRTY)
    } catch {
    }
}

OnReprocessClick(guiObj, *) {
    FsmDispatch(guiObj, EV_REPROCESS_CLICK)
}

PerformReload(guiObj, &outB64, &errJSON) {
    tmpTextFile := A_Temp "\karden_input_" guiObj.ZID "_" A_TickCount ".txt"
    try {
        FileDelete(tmpTextFile)
    } catch {
    }
    try {
        FileAppend(guiObj.SourceText, tmpTextFile, "UTF-8-RAW")
    } catch as e {
        return 1
    }
    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" render --language ' guiObj.Lang ' --zid ' guiObj.ZID ' --text-mode ' guiObj
        .TextMode ' --zoom ' G_DefaultZoom ' --theme ' G_Theme ' < "' tmpTextFile '"'
    try {
        exitCode := RunSilent(cmd, &outB64, &errJSON)
    } catch {
        exitCode := 1
    }
    try {
        FileDelete(tmpTextFile)
    } catch {
    }
    return exitCode
}

WatchFile(guiObj) {
    if (guiObj.FsmState != FSM_IDLE) {
        return
    }

    try {
        hwnd := guiObj.Hwnd
    } catch {
        hwnd := 0
    }
    if (hwnd == 0 || !WinExist("ahk_id " hwnd) || !guiObj.HasProp("wb") || !IsObject(guiObj.wb)) {
        if (guiObj.HasProp("TimerFn")) {
            SetTimer(guiObj.TimerFn, 0)
        }
        return
    }

    try {
        if (!FileExist(guiObj.TsvPath)) {
            return
        }
        currentMTime := FileGetTime(guiObj.TsvPath)
    } catch {
        return
    }

    FsmDispatch(guiObj, EV_FILE_CHANGED, currentMTime)
}

GuiClose(thisGui) {
    FsmDispatch(thisGui, EV_CLOSE)
    if (thisGui.HasProp("FsmState") && thisGui.FsmState == FSM_IDLE) {
        return 1
    }
}

GuiSize(thisGui, MinMax, Width, Height) {
    if (MinMax == -1)
        return
    thisGui.wvc.Move(, , Width - 20, Height - 65)
    btnY := Height - 40
    thisGui.SaveBtn.Move(15, btnY)
    thisGui.UpdateBtn.Move(135, btnY)
    thisGui.ReprocBtn.Move(255, btnY)
    thisGui.DeleteBtn.Move(375, btnY)
    thisGui.SendBtn.Move(495, btnY)
    thisGui.StatusTxt.Move(625, btnY, Width - 640)
    try {
        if (MinMax == 1) {
            thisGui.wb.document.body.classList.add("maximized")
        } else {
            thisGui.wb.document.body.classList.remove("maximized")
        }
    } catch {
    }
}

; ===================================================================================
; Hotkey & SmartAction Routing
; ===================================================================================
HandleSmartAction() {
    global G_PressCount, G_CapturedText, G_TapSingleMode, G_TapDoubleMode
    Taps := G_PressCount
    G_PressCount := 0

    textMode := G_TapSingleMode
    if (Taps >= 2) {
        textMode := G_TapDoubleMode
    }

    ; Release Alt, Control, and Shift to avoid Modifier Bleed
    KeyWait "Alt"
    KeyWait "Control"
    KeyWait "Shift"

    LaunchKardenwortWindow(G_CapturedText, textMode)
}

#MaxThreadsPerHotkey 2
; Register global hotkey Ctrl+Alt+Shift+F2 (English)
^+!F2::
{
    SetLanguage("en")
    TriggerSmartAction()
}

; Register global hotkey Ctrl+Alt+Shift+F3 (German)
^+!F3::
{
    SetLanguage("de")
    TriggerSmartAction()
}
#MaxThreadsPerHotkey 1

TriggerSmartAction() {
    global G_PressCount, G_CapturedText, G_MultiTapTimeout
    G_PressCount += 1
    if (G_PressCount == 1) {
        ; Use SmartCopy to securely grab selected text
        if SmartCopy(0.5, true) {
            G_CapturedText := A_Clipboard
            SetTimer(HandleSmartAction, -G_MultiTapTimeout)
        } else {
            G_PressCount := 0
            TrayTip("No text selected", "Kardenwort", 16)
        }
    }
}

; Register GUI hotkeys Ctrl+S and F5 for saving/updating in active Kardenwort windows
#HotIf WinActive("Kardenwort - ")
^s::
F5:: {
    activeHwnd := WinActive("A")
    if (activeHwnd) {
        guiObj := GuiFromHwnd(activeHwnd)
        if (guiObj) {
            if (!guiObj.FsmMemory["IsDirty"] && guiObj.FsmMemory["PendingUpdate"]) {
                OnUpdateClick(guiObj)
            } else {
                OnSaveClick(guiObj)
            }
        }
    }
}
#HotIf

; Dynamic mouse trigger: Left Click held + Middle Click double-tap to cycle language
~LButton & MButton:: {
    if (A_PriorHotkey == "~LButton & MButton" && A_TimeSincePriorHotkey < G_MultiTapTimeout) {
        CycleLanguage()
        TrayTip("Kardenwort language: " G_CurrentLang, "Kardenwort", 1)
    }
}

GetElementText(el) {
    if (!IsObject(el))
        return ""
    try {
        val := el.innerHTML
        if (val !== "")
            return val
    } catch {
    }
    try {
        val := el.textContent
        if (val !== "")
            return val
    } catch {
    }
    return ""
}

GuiEscape(thisGui) {
    try {
        el := thisGui.wb.document.activeElement
        if (el && el.tagName == "INPUT" && InStr(el.className, "edit-input")) {
            thisGui.wb.document.parentWindow.cancelActiveEdit()
            return
        }
        thisGui.wb.document.parentWindow.clearAllSelectionsAndNotify()
    } catch {
    }
}
#HotIf WinActive("Kardenwort - ")
$Enter::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            el := g.wb.document.activeElement
            if (el && el.tagName == "INPUT" && InStr(el.className, "edit-input")) {
                g.wb.document.parentWindow.commitActiveEdit()
                return
            }
        }
    } catch {
    }
    Send("{Enter}")
}

$Esc::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            el := g.wb.document.activeElement
            if (el && el.tagName == "INPUT" && InStr(el.className, "edit-input")) {
                g.wb.document.parentWindow.cancelActiveEdit()
                return
            }
        }
    } catch {
    }
    Send("{Esc}")
}

$F2::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            el := g.wb.document.activeElement
            if (el && el.tagName == "INPUT" && InStr(el.className, "edit-input")) {
                return
            }
            g.wb.document.parentWindow.editFocusedCell()
            return
        }
    } catch {
    }
    Send("{F2}")
}

$Delete::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            el := g.wb.document.activeElement
            if (el && el.tagName == "INPUT" && InStr(el.className, "edit-input")) {
                Send("{Delete}")
                return
            }
            OnDeleteClick(g)
            return
        }
    } catch {
    }
    Send("{Delete}")
}

$^a::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            el := g.wb.document.activeElement
            if (el && el.tagName == "INPUT" && InStr(el.className, "edit-input")) {
                g.wb.document.parentWindow.selectAllInActiveEdit()
                return
            }
        }
    } catch {
    }
    Send("^a")
}

$^c::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            g.wb.document.parentWindow.copySelection()
            return
        }
    } catch {
    }
    Send("^c")
}

$^z::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            el := g.wb.document.activeElement
            if (el && el.tagName == "INPUT" && InStr(el.className, "edit-input")) {
                Send("^z")
                return
            }
            g.wb.document.parentWindow.undo()
            try {
                if (g.wb.document.parentWindow.isDirty()) {
                    FsmDispatch(g, EV_DIRTY)
                } else {
                    FsmDispatch(g, EV_CLEAN)
                }
            } catch {
            }
            return
        }
    } catch {
    }
    Send("^z")
}

$^y::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            el := g.wb.document.activeElement
            if (el && el.tagName == "INPUT" && InStr(el.className, "edit-input")) {
                Send("^y")
                return
            }
            g.wb.document.parentWindow.redo()
            try {
                if (g.wb.document.parentWindow.isDirty()) {
                    FsmDispatch(g, EV_DIRTY)
                } else {
                    FsmDispatch(g, EV_CLEAN)
                }
            } catch {
            }
            return
        }
    } catch {
    }
    Send("^y")
}
#HotIf

UpdateStatus(guiObj, text) {
    if (!guiObj.HasOwnProp("StatusLog")) {
        guiObj.StatusLog := []
    }
    timeStr := FormatTime(A_Now, "HH:mm:ss")
    guiObj.StatusLog.InsertAt(1, "[" timeStr "] " text)
    if (guiObj.StatusLog.Length > 15) {
        guiObj.StatusLog.Pop()
    }
    guiObj.StatusTxt.Text := text
    guiObj.StatusTxt.Redraw()

    if (!guiObj.HasOwnProp("StatusHoverInit")) {
        guiObj.StatusHoverInit := true
        OnMessage(0x0200, HandleMouseMove)
    }
}

HandleMouseMove(wParam, lParam, msg, hwnd) {
    try {
        ctrl := GuiCtrlFromHwnd(hwnd)
        if (ctrl && ctrl.Name == "StatusTxt" && ctrl.Gui.HasOwnProp("StatusLog")) {
            logStr := ""
            for item in ctrl.Gui.StatusLog {
                logStr .= item ""
            }
            ToolTip(Trim(logStr, ""))
            SetTimer(HideStatusToolTip, -3000)
            return
        }
    } catch {
    }
    ToolTip()
}

HideStatusToolTip() {
    ToolTip()
}
