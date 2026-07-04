#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon

existingHwnd := 0
ow := A_DetectHiddenWindows
DetectHiddenWindows True
for win in WinGetList("ahk_class AutoHotkey") {
    try {
        if InStr(WinGetTitle(win), A_ScriptFullPath) {
            if (win != A_ScriptHwnd) {
                existingHwnd := win
                break
            }
        }
    } catch Any {
        continue
    }
}
DetectHiddenWindows ow

if (existingHwnd) {
    if (A_Args.Length > 0) {
        payload := ""
        for arg in A_Args {
            payload .= arg "`n"
        }
        CopyDataStruct := Buffer(3 * A_PtrSize)
        strBuf := Buffer(StrPut(payload, "UTF-16"))
        StrPut(payload, strBuf, "UTF-16")
        NumPut("Ptr", 1, CopyDataStruct, 0)
        NumPut("UInt", strBuf.Size, CopyDataStruct, A_PtrSize)
        NumPut("Ptr", strBuf.Ptr, CopyDataStruct, 2 * A_PtrSize)
        
        DetectHiddenWindows True
        SendMessage(0x004A, 0, CopyDataStruct.Ptr,, "ahk_id " existingHwnd)
    }
    ExitApp()
}

global G_Initialized := false
global G_BufferedArgs := []

OnMessage(0x004A, Receive_WM_COPYDATA)
OnMessage(0x0112, Disable_Alt_Menu)

Disable_Alt_Menu(wParam, lParam, msg, hwnd) {
    if ((wParam & 0xFFF0) == 0xF100) { ; SC_KEYMENU
        return 0
    }
}

A_IconHidden := 0

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
global FSM_RETEXTING := "RETEXTING"
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
global EV_RETEXT_CLICK := "EV_RETEXT_CLICK"
global EV_RETEXT_DONE := "EV_RETEXT_DONE"
global EV_RETEXT_FAILED := "EV_RETEXT_FAILED"
global EV_EXPORT_CLICK := "EV_EXPORT_CLICK"
global EV_EXPORT_DONE := "EV_EXPORT_DONE"
global EV_EXPORT_FAILED := "EV_EXPORT_FAILED"
global EV_CLOSE := "EV_CLOSE"
global EV_CLOSE_CANCEL := "EV_CLOSE_CANCEL"

global G_AutoInjectGracePeriodSec := 6
global G_AutoInjectMaxFileAgeDiffSec := 10
global G_FsmDispatching := false
global G_FsmTestMode
if !IsSet(G_FsmTestMode) {
    G_FsmTestMode := false
}

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
        "PendingExport", false,
        "PendingReprocess", false,
        "PendingRetext", false,
        "PendingClose", false
    )
}

FsmDispatch(guiObj, event, payload := "") {
    global G_FSM_TRANSITIONS, G_FsmDispatching

    if (G_FsmDispatching) {
        if (!guiObj.HasOwnProp("StatusLog")) {
            guiObj.StatusLog := []
        }
        timeStr := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        guiObj.StatusLog.InsertAt(1, "[" timeStr "] FSM: dropped re-entrant event " event " in state " guiObj.FsmState " @" guiObj.ZID)
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

    ; Clear the dispatch lock before running IO side effects
    ; so that any nested dispatches in IO functions (like completion events or compound flows) are allowed.
    G_FsmDispatching := false

    ; IO side-effects (if exists)
    if (transition.HasOwnProp("io") && transition.io != "") {
        ioFn := transition.io
        %ioFn%(guiObj, payload)
    }
}

FsmLog(guiObj, fromState, toState, event) {
    if (!guiObj.HasOwnProp("StatusLog")) {
        guiObj.StatusLog := []
    }
    timeStr := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    msg := "[" timeStr "] FSM: " fromState " -> " toState " (" event ") @" guiObj.ZID
    guiObj.StatusLog.InsertAt(1, msg)
    if (guiObj.StatusLog.Length > 15) {
        guiObj.StatusLog.Pop()
    }
}

FsmSelfCheck() {
    global G_FSM_TRANSITIONS
    validStates := Map(FSM_LOADING, 1, FSM_IDLE, 1, FSM_SAVING, 1, FSM_RELOADING, 1, FSM_REPROCESSING, 1, FSM_RETEXTING, 1, FSM_EXPORTING,
        1, FSM_CLOSING, 1, FSM_ERROR, 1)
    validEvents := Map(EV_RENDER_DONE, 1, EV_RENDER_FAILED, 1, EV_DIRTY, 1, EV_CLEAN, 1, EV_SAVE_CLICK, 1,
        EV_SAVE_SUCCESS, 1, EV_SAVE_FAILED, 1, EV_FILE_CHANGED, 1, EV_UPDATE_CLICK, 1, EV_RELOAD_DONE, 1,
        EV_RELOAD_FAILED, 1, EV_REPROCESS_CLICK, 1, EV_REPROCESS_DONE, 1, EV_REPROCESS_FAILED, 1, EV_RETEXT_CLICK, 1, EV_RETEXT_DONE, 1, EV_RETEXT_FAILED, 1, EV_EXPORT_CLICK, 1,
        EV_EXPORT_DONE, 1, EV_EXPORT_FAILED, 1, EV_CLOSE, 1, EV_CLOSE_CANCEL, 1)

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
    if (G_FsmTestMode) {
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
    if (G_HoverHighlightMvp == "1") {
        InjectHoverHighlightMvp(guiObj, G_HoverHighlightMvpBookmarks)
    }
    guiObj.wvc.Visible := true
    try {
        WinRedraw(guiObj.wvc.Hwnd)
        WinRedraw(guiObj.Hwnd)
    } catch {
    }

    try {
        tsvPath := GetElementText(guiObj.wb.document.getElementById("tsv-path"))
        guiObj.TsvPath := tsvPath
        
        ; Clean up any leftover update.js on load
        try {
            updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
            if FileExist(updateJsPath) {
                FileDelete(updateJsPath)
            }
        } catch {
        }
        
        SplitPath(tsvPath, &fileName)
        guiObj.Title := "Kardenwort - " guiObj.Lang " (" guiObj.TextMode ") - " fileName " - " (guiObj.HasProp("CurrentStatusText") ? guiObj.CurrentStatusText : "Ready")

        try {
            guiObj.FsmMemory["IsProgressive"] := GetElementText(guiObj.wb.document.getElementById("display-mode")) == "progressive"
        } catch {
            guiObj.FsmMemory["IsProgressive"] := false
        }
        try {
            guiObj.FsmMemory["RunEnrichment"] := GetElementText(guiObj.wb.document.getElementById("run-enrichment"))
        } catch {
            guiObj.FsmMemory["RunEnrichment"] := "auto"
        }
        try {
            guiObj.FsmMemory["IsLazy"] := GetElementText(guiObj.wb.document.getElementById("auto-inject-updates")) != "true"
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
    if (G_FsmTestMode) {
        return
    }
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
    UpdateButtonState(guiObj)
}

ActionCleanApply(guiObj, payload) {
    guiObj.FsmMemory["IsDirty"] := false
    return FSM_IDLE
}
ActionCleanIO(guiObj, payload) {
    UpdateButtonState(guiObj)
}

ActionSaveStartGuard(guiObj, payload) {
    if (G_FsmTestMode) {
        return guiObj.FsmMemory["IsDirty"]
    }
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
    if (G_FsmTestMode) {
        return
    }
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

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" edit-save --deltas "' tmpTextFile '" --zid ' guiObj.ZID ' --language ' guiObj.Lang ' --tsv "' guiObj.TsvPath '"'
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

    guiObj.FsmMemory["PendingUpdate"] := true

    if (guiObj.FsmMemory["PendingClose"]) {
        guiObj.FsmMemory["PendingClose"] := false
        return FSM_CLOSING
    } else if (guiObj.FsmMemory["PendingExport"]) {
        guiObj.FsmMemory["PendingExport"] := false
        return FSM_EXPORTING
    } else if (guiObj.FsmMemory["PendingRetext"]) {
        guiObj.FsmMemory["PendingRetext"] := false
        return FSM_RETEXTING
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
    } else if (guiObj.FsmState == FSM_RETEXTING) {
        ActionRetextStartIO(guiObj, "")
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
    guiObj.FsmMemory["PendingClose"] := false
    guiObj.FsmMemory["PendingExport"] := false
    guiObj.FsmMemory["PendingRetext"] := false
    guiObj.FsmMemory["PendingReprocess"] := false
    guiObj.FsmMemory["PendingUpdate"] := false
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
    if (currentMTime == guiObj.FsmMemory.Get("LastMTime", "")) {
        return false
    }

    currentJsMTime := ""
    updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
    
    if (FileExist(updateJsPath)) {
        currentJsMTime := FileGetTime(updateJsPath)
        
        ; If we haven't parsed this JS payload yet, read it to look for the finish signal
        if (currentJsMTime != guiObj.FsmMemory.Get("LastParsedJsMTime", "")) {
            guiObj.FsmMemory["LastParsedJsMTime"] := currentJsMTime
            jsCode := ""
            try {
                jsCode := FileRead(updateJsPath)
            } catch {
            }
            
            ; Instantly drop shields if the asynchronous background worker signals it is finished
            if (jsCode != "" && RegExMatch(jsCode, 'i)"stage"\s*:\s*"finished"')) {
                if (guiObj.FsmMemory.Has("ActiveReprocess")) {
                    guiObj.FsmMemory["ActiveReprocess"] := false
                }
                if (guiObj.FsmMemory.Has("ActiveRetext")) {
                    guiObj.FsmMemory["ActiveRetext"] := false
                }
            }
        }
    }

    if (!guiObj.FsmMemory["IsLazy"]) {
        if (currentJsMTime != "") {
            if (Abs(DateDiff(currentMTime, currentJsMTime, "Seconds")) <= G_AutoInjectMaxFileAgeDiffSec) {
                guiObj.FsmMemory["LastMTime"] := currentMTime
                guiObj.FsmMemory["AutoInjectRetries"] := 0
                UpdateStatus(guiObj, "Data injected automatically.")
                return false
            }
        }
    }

    isActiveReprocess := guiObj.FsmMemory.Has("ActiveReprocess") && guiObj.FsmMemory["ActiveReprocess"]
    isAutoInjecting := guiObj.FsmMemory["IsProgressive"] || isActiveReprocess
    if (isAutoInjecting) {
        ; Reset the grace period counter whenever a genuinely NEW TSV snapshot arrives
        if (currentMTime != guiObj.FsmMemory.Get("GracePeriodMTime", "")) {
            guiObj.FsmMemory["GracePeriodMTime"] := currentMTime
            guiObj.FsmMemory["AutoInjectRetries"] := 0
        }
        guiObj.FsmMemory["AutoInjectRetries"] += 1
        maxRetries := Round(G_AutoInjectGracePeriodSec * 1000 / G_FileWatcherIntervalMs)
        if (guiObj.FsmMemory["AutoInjectRetries"] < maxRetries) {
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
    if (G_FsmTestMode) {
        return
    }
    try {
        hwnd := guiObj.Hwnd
    } catch {
        hwnd := 0
    }
    if (hwnd == 0 || !WinExist("ahk_id " hwnd) || !guiObj.HasProp("wb") || !IsObject(guiObj.wb)) {
        return
    }

    htmlContent := B64Decode(payload.outB64)
    if (payload.scrollY) {
        scrollScript := "<style>body { visibility: hidden; }</style><script>window.addEventListener('load', function() { setTimeout(function() { window.scrollTo(0, " payload.scrollY "); document.body.style.visibility = 'visible'; }, 50); });</script>"
        htmlContent := StrReplace(htmlContent, "</body>", scrollScript "</body>")
    }
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
        if (G_HoverHighlightMvp == "1") {
            InjectHoverHighlightMvp(guiObj, G_HoverHighlightMvpBookmarks)
        }
        guiObj.wb.document.parentWindow.setSelectedRows(payload.selectedRowsJSON)
    } catch {
    }

    guiObj.wvc.Visible := true
    try {
        WinRedraw(guiObj.wvc.Hwnd)
        WinRedraw(guiObj.Hwnd)
    } catch {
    }

    try {
        guiObj.TsvPath := GetElementText(guiObj.wb.document.getElementById("tsv-path"))
        
        ; Clean up any leftover update.js on reload
        try {
            updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
            if FileExist(updateJsPath) {
                FileDelete(updateJsPath)
            }
        } catch {
        }
        
        if (FileExist(guiObj.TsvPath)) {
            guiObj.FsmMemory["LastMTime"] := FileGetTime(guiObj.TsvPath)
        } else {
            guiObj.FsmMemory["LastMTime"] := ""
        }
        try {
            guiObj.FsmMemory["IsProgressive"] := GetElementText(guiObj.wb.document.getElementById("display-mode")) == "progressive"
        } catch {
            guiObj.FsmMemory["IsProgressive"] := false
        }
        try {
            guiObj.FsmMemory["RunEnrichment"] := GetElementText(guiObj.wb.document.getElementById("run-enrichment"))
        } catch {
            guiObj.FsmMemory["RunEnrichment"] := "auto"
        }
        try {
            guiObj.FsmMemory["IsLazy"] := GetElementText(guiObj.wb.document.getElementById("auto-inject-updates")) != "true"
        } catch {
            guiObj.FsmMemory["IsLazy"] := false
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
    try {
        updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
        if FileExist(updateJsPath) {
            FileDelete(updateJsPath)
        }
    } catch {
    }
    UpdateButtonState(guiObj)
}

ActionReloadFailedApply(guiObj, payload) {
    return FSM_IDLE
}
ActionReloadFailedIO(guiObj, payload) {
    if (G_FsmTestMode) {
        return
    }
    UpdateStatus(guiObj, "Reload failed: render error")
    UpdateButtonState(guiObj)
}

ActionReprocessStartGuard(guiObj, payload) {
    return true
}
ActionReprocessStartApply(guiObj, payload) {
    guiObj.FsmMemory["ReprocessSelection"] := payload
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
    if (G_FsmTestMode) {
        return
    }

    guiObj.FsmMemory["ActiveReprocess"] := true
    UpdateStatus(guiObj, "Preparing re-process...")
    updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
    if FileExist(updateJsPath) {
        try {
            FileDelete(updateJsPath)
        } catch {
        }
    }
    try {
        guiObj.wb.document.parentWindow.startPolling()
    } catch {
    }
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
    if (G_FsmTestMode) {
        return
    }
    UpdateStatus(guiObj, "Re-processing started")
    UpdateButtonState(guiObj)
}

ActionReprocessFailedApply(guiObj, payload) {
    guiObj.FsmMemory["ActiveReprocess"] := false
    return FSM_IDLE
}
ActionReprocessFailedIO(guiObj, payload) {
    if (G_FsmTestMode) {
        return
    }
    UpdateStatus(guiObj, "Re-process failed")
    if (payload != "") {
        MsgBox("Failed to start re-processing:`n" payload, "Kardenwort Error", 16)
    }
    UpdateButtonState(guiObj)
}

ActionRetextStartGuard(guiObj, payload) {
    return true
}
ActionRetextStartApply(guiObj, payload) {
    guiObj.FsmMemory["RetextSelection"] := payload
    if (guiObj.FsmMemory["IsDirty"]) {
        guiObj.FsmMemory["PendingRetext"] := true
        return FSM_IDLE
    }
    return FSM_RETEXTING
}
ActionRetextStartIO(guiObj, payload) {
    if (guiObj.FsmMemory["PendingRetext"]) {
        FsmDispatch(guiObj, EV_SAVE_CLICK)
        return
    }
    if (G_FsmTestMode) {
        return
    }

    UpdateStatus(guiObj, "Preparing re-text...")
    updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
    if FileExist(updateJsPath) {
        try {
            FileDelete(updateJsPath)
        } catch {
        }
    }
    
    try {
        guiObj.wb.document.parentWindow.startPolling()
    } catch {
    }

    jsonStr := guiObj.FsmMemory["RetextSelection"]
    guiObj.FsmMemory.Delete("RetextSelection")

    tsvPathStr := StrReplace(guiObj.TsvPath, "\", "\\")
    manifest := '{"selected_row_ids": ' jsonStr ', "zid": "' guiObj.ZID '", "tsv_path": "' tsvPathStr '"}'
    tmpManifestFile := A_Temp "\karden_manifest_" guiObj.ZID "_retext.json"
    try {
        FileAppend(manifest, tmpManifestFile, "UTF-8-RAW")
    } catch as e {
        UpdateStatus(guiObj, "Manifest write failed")
        MsgBox("Failed to write temporary manifest file: " e.Message, "Kardenwort Error", 16)
        FsmDispatch(guiObj, EV_RETEXT_FAILED, "")
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" retext --selection-manifest "' tmpManifestFile '" --language ' guiObj.Lang ' --text-mode ' guiObj.TextMode
    guiObj.FsmMemory["ActiveRetext"] := true
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
        FsmDispatch(guiObj, EV_RETEXT_DONE, "")
    } else {
        FsmDispatch(guiObj, EV_RETEXT_FAILED, errJSON)
    }
}

ActionRetextDoneApply(guiObj, payload) {
    return FSM_IDLE
}
ActionRetextDoneIO(guiObj, payload) {
    if (G_FsmTestMode) {
        return
    }
    UpdateStatus(guiObj, "Re-text started")
    UpdateButtonState(guiObj)
}

ActionRetextFailedApply(guiObj, payload) {
    guiObj.FsmMemory["ActiveRetext"] := false
    return FSM_IDLE
}
ActionRetextFailedIO(guiObj, payload) {
    if (G_FsmTestMode) {
        return
    }
    UpdateStatus(guiObj, "Re-text failed")
    if (payload != "") {
        MsgBox("Failed to start re-texting:`n" payload, "Kardenwort Error", 16)
    }
    UpdateButtonState(guiObj)
}

ActionExportStartGuard(guiObj, payload) {
    return true
}
ActionExportStartApply(guiObj, payload) {
    guiObj.FsmMemory["ExportSelection"] := payload
    return FSM_EXPORTING
}
ActionExportStartIO(guiObj, payload) {
    if (G_FsmTestMode) {
        return
    }
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

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" export --selection-manifest "' tmpManifestFile '" --language ' guiObj.Lang
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
    if (G_FsmTestMode) {
        return
    }
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
    if (G_FsmTestMode) {
        return
    }
    UpdateStatus(guiObj, "Export failed")
    if (payload != "") {
        MsgBox("Failed to export favorites:`n" payload, "Kardenwort Error", 16)
    }
    UpdateButtonState(guiObj)
}

ActionCloseApply(guiObj, payload) {
    return FSM_CLOSING
}
ActionCloseCancelApply(guiObj, payload) {
    return FSM_IDLE
}
ActionCloseCancelIO(guiObj, payload) {
    UpdateButtonState(guiObj)
}
ActionCloseIO(guiObj, payload) {
    if (guiObj.FsmMemory["PendingClose"]) {
        FsmDispatch(guiObj, EV_SAVE_CLICK)
        return
    }
    if (guiObj.FsmMemory["IsDirty"]) {
        res := "Cancel"
        if (G_FsmTestMode) {
            if (payload != "") {
                res := payload
            }
        } else {
            res := MsgBox("You have unsaved edits. Save changes before closing?", "Kardenwort", "YesNoCancel Icon!")
        }
        if (res == "Cancel") {
            FsmDispatch(guiObj, EV_CLOSE_CANCEL)
            return
        } else if (res == "Yes") {
            guiObj.FsmMemory["PendingClose"] := true
            FsmDispatch(guiObj, EV_SAVE_CLICK)
            return
        }
    }
    if (G_FsmTestMode) {
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
        EV_CLEAN, { nextState: FSM_IDLE, apply: "ActionCleanApply", io: "ActionCleanIO" },
        EV_SAVE_CLICK, { nextState: FSM_SAVING, guard: "ActionSaveStartGuard", apply: "ActionSaveStartApply", io: "ActionSaveStartIO" },
        EV_FILE_CHANGED, { nextState: FSM_IDLE, guard: "ActionFileChangedGuard", apply: "ActionFileChangedApply", io: "ActionFileChangedIO" },
        EV_UPDATE_CLICK, { nextState: FSM_RELOADING, apply: "ActionUpdateClickApply", io: "ActionUpdateClickIO" },
        EV_REPROCESS_CLICK, { nextState: FSM_REPROCESSING, guard: "ActionReprocessStartGuard", apply: "ActionReprocessStartApply",
            io: "ActionReprocessStartIO" },
        EV_RETEXT_CLICK, { nextState: FSM_RETEXTING, guard: "ActionRetextStartGuard", apply: "ActionRetextStartApply",
            io: "ActionRetextStartIO" },
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
    FSM_RETEXTING, Map(
        EV_RETEXT_DONE, { nextState: FSM_IDLE, apply: "ActionRetextDoneApply", io: "ActionRetextDoneIO" },
        EV_RETEXT_FAILED, { nextState: FSM_IDLE, apply: "ActionRetextFailedApply", io: "ActionRetextFailedIO" },
        EV_CLOSE, { nextState: FSM_CLOSING, apply: "ActionCloseApply", io: "ActionCloseIO" }
    ),
    FSM_REPROCESSING, Map(
        EV_REPROCESS_DONE, { nextState: FSM_IDLE, apply: "ActionReprocessDoneApply", io: "ActionReprocessDoneIO" },
        EV_REPROCESS_FAILED, { nextState: FSM_IDLE, apply: "ActionReprocessFailedApply", io: "ActionReprocessFailedIO" },
        EV_CLOSE, { nextState: FSM_CLOSING, apply: "ActionCloseApply", io: "ActionCloseIO" }
    ),
    FSM_EXPORTING, Map(
        EV_EXPORT_DONE, { nextState: FSM_IDLE, apply: "ActionExportDoneApply", io: "ActionExportDoneIO" },
        EV_EXPORT_FAILED, { nextState: FSM_IDLE, apply: "ActionExportFailedApply", io: "ActionExportFailedIO" },
        EV_CLOSE, { nextState: FSM_CLOSING, apply: "ActionCloseApply", io: "ActionCloseIO" }
    ),
    FSM_CLOSING, Map(
        EV_SAVE_CLICK, { nextState: FSM_SAVING, guard: "ActionSaveStartGuard", apply: "ActionSaveStartApply", io: "ActionSaveStartIO" },
        EV_CLOSE_CANCEL, { nextState: FSM_IDLE, apply: "ActionCloseCancelApply", io: "ActionCloseCancelIO" }
    ),
    FSM_ERROR, Map(
        EV_CLOSE, { nextState: FSM_ERROR, io: "ActionCloseIO" }
    )
)

FsmSelfCheck()
; ===================================================================================
; Configuration & Globals
; ===================================================================================
global G_ActiveWindows := Map()
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
global G_HoverHighlightMvp := "0"
global G_HoverHighlightMvpBookmarks := "3"
global G_KeyTogglePointer := "Alt"

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
    global G_AutoInjectGracePeriodSec := IniRead(configPath, "Settings", "AutoInjectGracePeriodSec", 6)
    global G_AutoInjectMaxFileAgeDiffSec := IniRead(configPath, "Settings", "AutoInjectMaxFileAgeDiffSec", 10)
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
    global G_HoverHighlightMvp := IniRead(configPath, "Settings", "HoverHighlightMvp", "0")
    global G_HoverHighlightMvpBookmarks := IniRead(configPath, "Settings", "HoverHighlightMvpBookmarks", "3")
    global G_KeyTogglePointer := IniRead(configPath, "Hotkey", "key_toggle_pointer", "Alt")


    if (G_DeskPythonPath == "" || !FileExist(G_DeskPythonPath)) {
        MsgBox("Python interpreter not found: " G_DeskPythonPath, "Kardenwort Error", 16)
        ExitApp()
    }
    if (G_DeskScriptPath == "" || !FileExist(G_DeskScriptPath)) {
        MsgBox("Desk script not found: " G_DeskScriptPath, "Kardenwort Error", 16)
        ExitApp()
    }
}

RegisterPointerToggleHotkeys() {
    global G_KeyTogglePointer
    if (G_KeyTogglePointer == "")
        return
        
    keys := StrSplit(G_KeyTogglePointer, " ")
    for k in keys {
        k := Trim(k)
        if (k == "")
            continue
            
        RegisterSingleHotkey(k)
    }
}

RegisterSingleHotkey(hkStr) {
    if InStr(hkStr, "+") {
        parts := StrSplit(hkStr, "+")
        
        allModifiers := true
        for p in parts {
            p := Trim(p)
            if !(p = "Ctrl" || p = "Alt" || p = "Shift" || p = "Win" || p = "LAlt" || p = "RAlt" || p = "LCtrl" || p = "RCtrl" || p = "LShift" || p = "RShift") {
                allModifiers := false
                break
            }
        }
        
        if (allModifiers) {
            if (parts.Length == 2) {
                p1 := parts[1]
                p2 := parts[2]
                RegisterAHKHotkey("~" GetModifierSymbol(p1) p2, p2)
                RegisterAHKHotkey("~" GetModifierSymbol(p2) p1, p1)
            } else if (parts.Length == 3) {
                p1 := parts[1]
                p2 := parts[2]
                p3 := parts[3]
                RegisterAHKHotkey("~" GetModifierSymbol(p1) GetModifierSymbol(p2) p3, p3)
                RegisterAHKHotkey("~" GetModifierSymbol(p1) GetModifierSymbol(p3) p2, p2)
                RegisterAHKHotkey("~" GetModifierSymbol(p2) GetModifierSymbol(p3) p1, p1)
            }
        } else {
            ahkHk := ""
            lastPart := parts[parts.Length]
            for i, p in parts {
                if (i < parts.Length) {
                    ahkHk .= GetModifierSymbol(p)
                }
            }
            ahkHk .= lastPart
            RegisterAHKHotkey(ahkHk, lastPart)
        }
    } else {
        hkPrefix := ""
        if (hkStr = "Alt" || hkStr = "Ctrl" || hkStr = "Shift" || hkStr = "Win" || hkStr = "LAlt" || hkStr = "RAlt" || hkStr = "LCtrl" || hkStr = "RCtrl" || hkStr = "LShift" || hkStr = "RShift") {
            hkPrefix := "~"
        }
        RegisterAHKHotkey(hkPrefix hkStr, hkStr)
    }
}

GetModifierSymbol(modName) {
    if (modName = "Ctrl" || modName = "LCtrl" || modName = "RCtrl")
        return "^"
    if (modName = "Alt" || modName = "LAlt" || modName = "RAlt")
        return "!"
    if (modName = "Shift" || modName = "LShift" || modName = "RShift")
        return "+"
    if (modName = "Win")
        return "#"
    return ""
}

RegisterAHKHotkey(ahkHkName, keyToWait) {
    try {
        Hotkey(ahkHkName, OnToggleHotkeyPress.Bind(keyToWait))
    } catch Any as e {
        ; Ignore invalid hotkeys
    }
}

OnToggleHotkeyPress(keyToWait, thisHotkey) {
    activeHwnd := WinActive("A")
    if (!activeHwnd)
        return
        
    guiObj := GuiFromHwnd(activeHwnd)
    if (!guiObj || !guiObj.HasProp("wb"))
        return
        
    ToggleSelectableTextMode(guiObj, true)
    
    KeyWait(keyToWait)
    
    ToggleSelectableTextMode(guiObj, false)
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
    foundTsvPath := ""
    tsvPattern := fileDir "\" ZID "-*.tsv"
    loop files, tsvPattern {
        foundTsv := A_LoopFileName
        foundTsvPath := A_LoopFileFullPath
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

    LaunchKardenwortWindow(sourceText, inferredMode, ZID, foundTsvPath)
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

if (A_ScriptFullPath = A_LineFile) {
    ; Initialize configuration and tray menu
    LoadConfig()
    RegisterPointerToggleHotkeys()
    InitializeTrayMenu()

    global G_Initialized := true

    ProcessArgs(A_Args)

    if (G_BufferedArgs.Length > 0) {
        ProcessArgs(G_BufferedArgs)
        G_BufferedArgs := []
    }
}

Receive_WM_COPYDATA(wParam, lParam, msg, hwnd) {
    global G_Initialized, G_BufferedArgs
    strPtr := NumGet(lParam, 2 * A_PtrSize, "Ptr")
    payload := StrGet(strPtr, "UTF-16")
    args := StrSplit(Trim(payload, "`n"), "`n")
    
    if (!G_Initialized) {
        for arg in args {
            G_BufferedArgs.Push(arg)
        }
    } else {
        ProcessArgs(args)
    }
    return true
}

ProcessArgs(argsArray) {
    if (argsArray.Length > 0) {
        textMode := "multi"
        i := 1
        while (i <= argsArray.Length) {
            arg := argsArray[i]
            if (arg == "--restore") {
                LaunchRestore(argsArray[i + 1])
                i += 2
            } else if (arg == "--desk") {
                LaunchDesk(argsArray[i + 1], textMode)
                i += 2
            } else if (arg == "--text-mode") {
                textMode := argsArray[i + 1]
                i += 2
            } else {
                i += 1
            }
        }
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
LaunchKardenwortWindow(sourceText, textMode, presetZID := "", tsvPath := "") {
    ZID := presetZID != "" ? presetZID : A_Now
    
    global G_ActiveWindows
    sessionID := tsvPath != "" ? tsvPath : ZID
    if (G_ActiveWindows.Has(sessionID)) {
        hwnd := G_ActiveWindows[sessionID]
        if WinExist("ahk_id " hwnd) {
            WinActivate("ahk_id " hwnd)
            return
        } else {
            G_ActiveWindows.Delete(sessionID)
        }
    }
    
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
    SaveBtn := MyGui.Add("Text", "x15 y615 w100 h30 Center +Border +0x200 " G_GuiTextColor " Disabled", "Save (Ctrl+S)")
    UpdateBtn := MyGui.Add("Text", "x125 y615 w100 h30 Center +Border +0x200 +Hidden " G_GuiTextColor, "⟳ Update")
    RetextBtn := MyGui.Add("Text", "x235 y615 w100 h30 Center +Border +0x200 " G_GuiTextColor, "Re-text")
    ReprocBtn := MyGui.Add("Text", "x345 y615 w100 h30 Center +Border +0x200 " G_GuiTextColor, "Re-word")
    DeleteBtn := MyGui.Add("Text", "x455 y615 w100 h30 Center +Border +0x200 " G_GuiTextColor, "Delete")
    SendBtn := MyGui.Add("Text", "x565 y615 w100 h30 Center +Border +0x200 " G_GuiTextColor, "Send to Anki")
    PointerBtn := MyGui.Add("Text", "x675 y615 w100 h30 Center +Border +0x200 " G_GuiTextColor, "Hand Tool")


    ; Store references on GUI object
    MyGui.wb := wb
    MyGui.wvc := wvc
    MyGui.SaveBtn := SaveBtn
    MyGui.UpdateBtn := UpdateBtn
    MyGui.SendBtn := SendBtn
    MyGui.DeleteBtn := DeleteBtn
    MyGui.RetextBtn := RetextBtn
    MyGui.ReprocBtn := ReprocBtn
    MyGui.PointerBtn := PointerBtn

    MyGui.ZID := ZID
    MyGui.Lang := lang
    MyGui.TextMode := textMode
    MyGui.SourceText := sourceText
    MyGui.TsvPath := tsvPath
    MyGui.SessionID := sessionID
    MyGui.selectableTextMode := false
    MyGui.persistentSelectableTextMode := false
    FsmInit(MyGui)

    SaveBtn.OnEvent("Click", OnSaveClick.Bind(MyGui))
    UpdateBtn.OnEvent("Click", OnUpdateClick.Bind(MyGui))
    SendBtn.OnEvent("Click", OnSendToAnkiClick.Bind(MyGui))
    DeleteBtn.OnEvent("Click", OnDeleteClick.Bind(MyGui))
    RetextBtn.OnEvent("Click", OnRetextClick.Bind(MyGui))
    ReprocBtn.OnEvent("Click", OnReprocessClick.Bind(MyGui))
    PointerBtn.OnEvent("Click", OnPointerToggleClick.Bind(MyGui))

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
    
    G_ActiveWindows[sessionID] := MyGui.Hwnd

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
    if (tsvPath != "") {
        cmd := cmd ' --tsv "' tsvPath '"'
    }
    exitCode := 1
    try {
        exitCode := RunSilent(cmd, &outB64, &errJSON)
    } catch as e {
        errJSON := "RunSilent threw an exception: " e.Message
    }
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
    if (action == "JS_Error") {
        MsgBox("JavaScript Error: " value, "Kardenwort JS Error", 16)
        return
    }
    if (action == "dirty") {
        if (value == "true") {
            FsmDispatch(guiObj, EV_DIRTY)
        } else {
            FsmDispatch(guiObj, EV_CLEAN)
        }
    }
    if (action == "finished") {
        try {
            guiObj.FsmMemory["LastMTime"] := FileGetTime(guiObj.TsvPath)
        } catch {
        }
        guiObj.FsmMemory["PendingUpdate"] := false
        
        ; Delete the temporary .update.js file now that the worker is finished
        updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
        if FileExist(updateJsPath) {
            try {
                FileDelete(updateJsPath)
            } catch {
            }
        }

        if (guiObj.FsmMemory.Has("ActiveRetext") && guiObj.FsmMemory["ActiveRetext"]) {
            guiObj.FsmMemory["ActiveRetext"] := false
            FsmDispatch(guiObj, EV_UPDATE_CLICK)
        } else {
            if (guiObj.FsmMemory.Has("ActiveReprocess")) {
                guiObj.FsmMemory["ActiveReprocess"] := false
            }
            UpdateButtonState(guiObj)
        }
    }
}

UpdateButtonState(guiObj) {
    if (!guiObj.HasProp("FsmState") || !guiObj.HasProp("FsmMemory")) {
        return
    }

    if (guiObj.FsmState == FSM_RELOADING || guiObj.FsmState == FSM_REPROCESSING || guiObj.FsmState == FSM_RETEXTING ||
        guiObj.FsmState == FSM_LOADING || guiObj.FsmState == FSM_SAVING || guiObj.FsmState == FSM_CLOSING) {
        guiObj.UpdateBtn.Visible := false
        guiObj.SaveBtn.Enabled := false
        guiObj.SendBtn.Enabled := false
        guiObj.DeleteBtn.Enabled := false
        guiObj.RetextBtn.Enabled := false
        guiObj.ReprocBtn.Enabled := false
        return
    }

    if (guiObj.FsmState == FSM_EXPORTING) {
        guiObj.UpdateBtn.Visible := false
        guiObj.SaveBtn.Enabled := false
        guiObj.SendBtn.Enabled := false
        guiObj.DeleteBtn.Enabled := false
        guiObj.RetextBtn.Enabled := false
        guiObj.ReprocBtn.Enabled := false
        UpdateStatus(guiObj, "Exporting favorites...")
        return
    }

    isDirty := guiObj.FsmMemory["IsDirty"]
    pending := guiObj.FsmMemory["PendingUpdate"]

    guiObj.SaveBtn.Enabled := isDirty
    guiObj.SendBtn.Enabled := true
    guiObj.DeleteBtn.Enabled := true
    guiObj.RetextBtn.Enabled := true
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
    } else {
        UpdateStatus(guiObj, "Ready")
    }
}

OnUpdateClick(guiObj, *) {
    FsmDispatch(guiObj, EV_UPDATE_CLICK)
}

OnSaveClick(guiObj, *) {
    FsmDispatch(guiObj, EV_SAVE_CLICK)
}

OnSendToAnkiClick(guiObj, *) {
    try {
        jsonStr := guiObj.wb.document.parentWindow.getSelectedRows()
    } catch {
        jsonStr := ""
    }
    if (jsonStr == "" || jsonStr == "[]") {
        MsgBox("Please select rows to export.", "Kardenwort", 48)
        UpdateStatus(guiObj, "Ready")
        return
    }
    FsmDispatch(guiObj, EV_EXPORT_CLICK, jsonStr)
}

OnDeleteClick(guiObj, *) {
    try {
        guiObj.wb.document.parentWindow.deleteSelectedRows()
        FsmDispatch(guiObj, EV_DIRTY)
    } catch {
    }
}

OnRetextClick(guiObj, *) {
    try {
        guiObj.wb.document.parentWindow.clearMVPBookmarks()
    } catch {
    }
    try {
        jsonStr := guiObj.wb.document.parentWindow.getSelectedRows()
    } catch {
        jsonStr := "[]"
    }
    if (jsonStr == "") {
        jsonStr := "[]"
    }
    FsmDispatch(guiObj, EV_RETEXT_CLICK, jsonStr)
}

OnReprocessClick(guiObj, *) {
    try {
        jsonStr := guiObj.wb.document.parentWindow.getSelectedRows()
    } catch {
        jsonStr := ""
    }
    if (jsonStr == "" || jsonStr == "[]") {
        MsgBox("Please select rows to re-process.", "Kardenwort", 48)
        UpdateStatus(guiObj, "Ready")
        return
    }
    FsmDispatch(guiObj, EV_REPROCESS_CLICK, jsonStr)
}

OnPointerToggleClick(guiObj, *) {
    ToggleSelectableTextMode(guiObj, "", true)
}

ToggleSelectableTextMode(guiObj, state := "", isPersistent := false) {
    currState := guiObj.HasProp("selectableTextMode") ? guiObj.selectableTextMode : false
    
    if (isPersistent) {
        pState := (state !== "") ? state : !(guiObj.HasProp("persistentSelectableTextMode") ? guiObj.persistentSelectableTextMode : false)
        guiObj.persistentSelectableTextMode := pState
        newState := pState
    } else {
        if (state !== "") {
            if (state) {
                newState := true
            } else {
                newState := guiObj.HasProp("persistentSelectableTextMode") ? guiObj.persistentSelectableTextMode : false
            }
        } else {
            newState := !currState
        }
    }
    
    if (currState == newState) {
        UpdateButtonText(guiObj, newState)
        return
    }
        
    guiObj.selectableTextMode := newState
    UpdateButtonText(guiObj, newState)
    UpdateWebViewMode(guiObj, newState)
}

UpdateButtonText(guiObj, state) {
    if (state) {
        guiObj.PointerBtn.Text := "Select Text"
    } else {
        guiObj.PointerBtn.Text := "Hand Tool"
    }
}

UpdateWebViewMode(guiObj, state) {
    try {
        if (guiObj.wb && guiObj.wb.document && guiObj.wb.document.parentWindow) {
            guiObj.wb.document.parentWindow.setSelectableTextMode(state ? true : false)
        }
    } catch {
        ; Ignore if webview is not ready yet
    }
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
    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" render --language ' guiObj.Lang ' --zid ' guiObj.ZID ' --text-mode ' guiObj.TextMode ' --zoom ' G_DefaultZoom ' --theme ' G_Theme ' < "' tmpTextFile '"'
    if (guiObj.HasProp("TsvPath") && guiObj.TsvPath != "") {
        cmd := cmd ' --tsv "' guiObj.TsvPath '"'
    }
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

    try {
        updateJsPath := RegExReplace(guiObj.TsvPath, "(?i)\.tsv$", ".update.js")
        if FileExist(updateJsPath) {
            jsMTime := FileGetTime(updateJsPath)
            if (!guiObj.FsmMemory.Has("LastJsMTime") || guiObj.FsmMemory["LastJsMTime"] != jsMTime) {
                guiObj.FsmMemory["LastJsMTime"] := jsMTime
                if (!guiObj.FsmMemory["IsLazy"]) {
                    jsCode := FileRead(updateJsPath, "UTF-8")
                    try {
                        guiObj.wb.document.parentWindow.eval(jsCode)
                    } catch {
                    }
                }
                try {
                    currentMTime := FileGetTime(guiObj.TsvPath)
                } catch {
                }
            }
        } else {
            if (guiObj.FsmMemory.Has("LastJsMTime")) {
                guiObj.FsmMemory.Delete("LastJsMTime")
            }
        }
    } catch {
    }

    FsmDispatch(guiObj, EV_FILE_CHANGED, currentMTime)
}

GuiClose(thisGui) {
    global G_ActiveWindows
    if (thisGui.HasProp("SessionID") && G_ActiveWindows.Has(thisGui.SessionID)) {
        G_ActiveWindows.Delete(thisGui.SessionID)
    }
    FsmDispatch(thisGui, EV_CLOSE)
    return 1
}

GuiSize(thisGui, MinMax, Width, Height) {
    if (MinMax == -1)
        return
    thisGui.wvc.Move(, , Width - 20, Height - 65)
    btnY := Height - 40
    thisGui.SaveBtn.Move(15, btnY)
    thisGui.UpdateBtn.Move(125, btnY)
    thisGui.RetextBtn.Move(235, btnY)
    thisGui.ReprocBtn.Move(345, btnY)
    thisGui.DeleteBtn.Move(455, btnY)
    thisGui.SendBtn.Move(565, btnY)
    thisGui.PointerBtn.Move(675, btnY)

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
            try {
                if (g.wb.document.parentWindow.clearMVPBookmarks()) {
                    return
                }
            } catch {
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

$F4::
{
    activeHwnd := WinActive("A")
    try {
        g := GuiFromHwnd(activeHwnd)
        if (g && g.HasProp("wb")) {
            ToggleSelectableTextMode(g, "", true)
            return
        }
    } catch {
    }
    Send("{F4}")
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
    guiObj.CurrentStatusText := text
    try {
        if (guiObj.HasProp("TsvPath") && guiObj.TsvPath != "") {
            SplitPath(guiObj.TsvPath, &fileName)
        } else {
            fileName := ""
        }
    } catch {
        fileName := ""
    }
    if (fileName != "") {
        guiObj.Title := "Kardenwort - " guiObj.Lang " (" guiObj.TextMode ") - " fileName " - " text
    } else {
        guiObj.Title := "Kardenwort - " guiObj.Lang " (" guiObj.TextMode ") - " text
    }

    if (G_FsmTestMode) {
        return
    }
}

InjectHoverHighlightMvp(guiObj, bookmarksN) {
    try {
        doc := guiObj.wb.document
        if (!doc)
            return

        try {
            doc.parentWindow.__mvpBookmarks := bookmarksN
        } catch {
        }

        if (doc.getElementById("hl-mvp-style"))
            return

        styleEl := doc.createElement("style")
        styleEl.id := "hl-mvp-style"
        styleEl.type := "text/css"

        css := ""
        css .= "body.theme-dark #source-container span.word.hl-mvp-pin,"
        css .= "body.theme-dark #translation-container span.word.hl-mvp-pin,"
        css .= "body.theme-dark #source-container span.word.hl-mvp-hover,"
        css .= "body.theme-dark #translation-container span.word.hl-mvp-hover,"
        css .= "body.theme-white #source-container span.word.hl-mvp-pin,"
        css .= "body.theme-white #translation-container span.word.hl-mvp-pin,"
        css .= "body.theme-white #source-container span.word.hl-mvp-hover,"
        css .= "body.theme-white #translation-container span.word.hl-mvp-hover {"
        css .= "  border: 1px dashed #39c5ff !important;"
        css .= "  border-radius: 4px !important;"
        css .= "  margin: -1px !important;"
        css .= "}"
        css .= "body.theme-light #source-container span.word.hl-mvp-pin,"
        css .= "body.theme-light #translation-container span.word.hl-mvp-pin,"
        css .= "body.theme-light #source-container span.word.hl-mvp-hover,"
        css .= "body.theme-light #translation-container span.word.hl-mvp-hover {"
        css .= "  border: 1px dashed #0969da !important;"
        css .= "  border-radius: 4px !important;"
        css .= "  margin: -1px !important;"
        css .= "}"
        css .= "#source-container span.word,"
        css .= "#translation-container span.word {"
        css .= "  cursor: pointer;"
        css .= "}"
        css .= "body.theme-dark #translation-container span.word:hover {"
        css .= "  background-color: rgba(255, 255, 255, 0.1);"
        css .= "  border-radius: 4px;"
        css .= "}"
        css .= "#source-container span.word,"
        css .= "#source-container span.word * {"
        css .= "  border: none !important;"
        css .= "  outline: none !important;"
        css .= "  font-family: inherit !important;"
        css .= "  font-size: inherit !important;"
        css .= "  font-weight: inherit !important;"
        css .= "}"
        css .= "body.theme-light #translation-container span.word:hover,"
        css .= "body.theme-white #translation-container span.word:hover {"
        css .= "  background-color: rgba(0, 0, 0, 0.06);"
        css .= "  border-radius: 4px;"
        css .= "}"
        css .= "body.text-selection-mode-active .source-text,"
        css .= "body.text-selection-mode-active .source-text *,"
        css .= "body.text-selection-mode-active #source-container,"
        css .= "body.text-selection-mode-active #source-container *,"
        css .= "body.text-selection-mode-active #translation-container,"
        css .= "body.text-selection-mode-active #translation-container *,"
        css .= "body.text-selection-mode-active #lemma-table,"
        css .= "body.text-selection-mode-active #lemma-table *,"
        css .= "body.text-selection-mode-active #lemma-table td,"
        css .= "body.text-selection-mode-active #lemma-table th {"
        css .= "  -webkit-user-select: text !important;"
        css .= "  -moz-user-select: text !important;"
        css .= "  -ms-user-select: text !important;"
        css .= "  user-select: text !important;"
        css .= "  cursor: text !important;"
        css .= "}"
        css .= "body.text-selection-mode-active #lemma-table tr:hover td {"
        css .= "  background: transparent !important;"
        css .= "}"
        css .= "body.text-selection-mode-active #lemma-table tr.selected td {"
        css .= "  background: transparent !important;"
        css .= "  color: inherit !important;"
        css .= "}"
        css .= "body.text-selection-mode-active span.word,"
        css .= "body.text-selection-mode-active span.token,"
        css .= "body.text-selection-mode-active #source-container span.word,"
        css .= "body.text-selection-mode-active #translation-container span.word,"
        css .= "body.text-selection-mode-active #source-container span.token,"
        css .= "body.text-selection-mode-active #translation-container span.token {"
        css .= "  cursor: text !important;"
        css .= "  background-color: transparent !important;"
        css .= "  background: transparent !important;"
        css .= "  color: inherit !important;"
        css .= "  border: none !important;"
        css .= "  outline: none !important;"
        css .= "  padding: 0 !important;"
        css .= "  margin: 0 !important;"
        css .= "  text-decoration: none !important;"
        css .= "  border-radius: 0 !important;"
        css .= "  box-shadow: none !important;"
        css .= "}"
        css .= "body.text-selection-mode-active span.word:hover,"
        css .= "body.text-selection-mode-active #translation-container span.word:hover {"
        css .= "  background-color: transparent !important;"
        css .= "}"

        try {
            styleEl.appendChild(doc.createTextNode(css))
        } catch {
            try {
                styleEl.text := css
            } catch {
                try {
                    styleEl.styleSheet.cssText := css
                } catch {
                }
            }
        }

        try {
            doc.head.appendChild(styleEl)
        } catch {
            doc.body.appendChild(styleEl)
        }

        scriptEl := doc.createElement("script")
        scriptEl.id := "hl-mvp-script"
        scriptEl.type := "text/javascript"
        scriptEl.setAttribute("data-bookmarks", bookmarksN)

        js := ""
        js .= "(function() {"
        js .= "  try {"
        js .= "  function addEvent(el, type, fn) {"
        js .= "    if (el.addEventListener) el.addEventListener(type, fn, false);"
        js .= "    else if (el.attachEvent) el.attachEvent('on' + type, fn);"
        js .= "    else el['on' + type] = fn;"
        js .= "  }"
        js .= "  function addClass(el, name) {"
        js .= "    try { if (el && el.classList) el.classList.add(name); } catch(e) {}"
        js .= "  }"
        js .= "  function removeClass(el, name) {"
        js .= "    try { if (el && el.classList) el.classList.remove(name); } catch(e) {}"
        js .= "  }"
        js .= "  function isAttached(el) {"
        js .= "    while (el) {"
        js .= "      if (el === document.documentElement) return true;"
        js .= "      el = el.parentNode;"
        js .= "    }"
        js .= "    return false;"
        js .= "  }"
        js .= "  function escapeHtml(str) {"
        js .= "    if (!str) return '';"
        js .= "    return str"
        js .= "      .replace(new RegExp(String.fromCharCode(38), 'g'), '&amp;')"
        js .= "      .replace(new RegExp(String.fromCharCode(60), 'g'), '&lt;')"
        js .= "      .replace(new RegExp(String.fromCharCode(62), 'g'), '&gt;')"
        js .= "      .replace(new RegExp(String.fromCharCode(34), 'g'), '&quot;')"
        js .= "      .replace(new RegExp(String.fromCharCode(39), 'g'), '&#039;');"
        js .= "  }"
        js .= "  var bookmarks = [];"
        js .= "  var sourceSpansArray = [];"
        js .= "  var transSpansArray = [];"
        js .= "  var N = 3;"
        js .= "  var isIndexBuilt = false;"
        js .= "  if (window.__mvpBookmarks) N = parseInt(window.__mvpBookmarks, 10);"
        js .= "  else {"
        js .= "    var scriptEl = document.getElementById('hl-mvp-script');"
        js .= "    if (scriptEl) {"
        js .= "      var db = scriptEl.getAttribute('data-bookmarks');"
        js .= "      if (db) N = parseInt(db, 10);"
        js .= "    }"
        js .= "  }"
        js .= "  if (isNaN(N) || N < 1) N = 3;"
        js .= "  function tokenizeText(text) {"
        js .= "    var rx;"
        js .= "    try {"
        js .= "      rx = new RegExp('([\\p{L}0-9\\x27]+)', 'gu');"
        js .= "    } catch(e) {"
        js .= "      rx = new RegExp('([a-zA-Z0-9\\x27\\u0400-\\u04FF\\u00C0-\\u017F]+)', 'g');"
        js .= "    }"
        js .= "    return text.split(rx);"
        js .= "  }"
        js .= "  function tokenizeTranslation() {"
        js .= "    var tc = document.getElementById('translation-container');"
        js .= "    if (!tc) return;"
        js .= "    var divs = tc.getElementsByTagName('div');"
        js .= "    for (var i = 0; i < divs.length; i++) {"
        js .= "      var div = divs[i];"
        js .= "      var firstChild = div.firstChild;"
        js .= "      if (firstChild && firstChild.nodeType === 1 && firstChild.tagName === 'SPAN' && firstChild.classList && firstChild.classList.contains('word')) {"
        js .= "        if (firstChild.classList.contains('hl-mvp')) continue;"
        js .= "        var childSpans = div.getElementsByTagName('span');"
        js .= "        for (var j = 0; j < childSpans.length; j++) {"
        js .= "          var span = childSpans[j];"
        js .= "          if (span.classList && span.classList.contains('word')) {"
        js .= "            addClass(span, 'hl-mvp');"
        js .= "            span.setAttribute('data-line-idx', i);"
        js .= "          }"
        js .= "        }"
        js .= "      } else {"
        js .= "        var text = div.textContent || div.innerText || '';"
        js .= "        var parts = tokenizeText(text);"
        js .= "        var html = '';"
        js .= "        for (var k = 0; k < parts.length; k++) {"
        js .= "          var part = parts[k];"
        js .= "          if (!part) continue;"
        js .= "          if (k % 2 === 1) {"
        js .= "            var lc = part.toLowerCase();"
        js .= "            html += '<span class=`"word hl-mvp`" data-lower-clean=`"' + escapeHtml(lc) + '`" data-line-idx=`"' + i + '`">' + escapeHtml(part) + '</span>';"
        js .= "          } else {"
        js .= "            html += escapeHtml(part);"
        js .= "          }"
        js .= "        }"
        js .= "        div.innerHTML = html;"
        js .= "      }"
        js .= "    }"
        js .= "  }"
        js .= "  function buildLcIndex() {"
        js .= "    sourceSpansArray = [];"
        js .= "    transSpansArray = [];"
        js .= "    var sc = document.getElementById('source-container');"
        js .= "    if (sc) {"
        js .= "      var srcSpans = sc.getElementsByTagName('span');"
        js .= "      if (srcSpans.length > 0) isIndexBuilt = true;"
        js .= "      for (var i = 0; i < srcSpans.length; i++) {"
        js .= "        var span = srcSpans[i];"
        js .= "        if (span.classList && span.classList.contains('word')) {"
        js .= "          span.setAttribute('data-mvp-idx', sourceSpansArray.length);"
        js .= "          span.setAttribute('data-mvp-type', 'source');"
        js .= "          sourceSpansArray.push(span);"
        js .= "        }"
        js .= "      }"
        js .= "    }"
        js .= "    var tc = document.getElementById('translation-container');"
        js .= "    if (tc) {"
        js .= "      var transSpans = tc.getElementsByTagName('span');"
        js .= "      for (var j = 0; j < transSpans.length; j++) {"
        js .= "        var span = transSpans[j];"
        js .= "        if (span.classList && span.classList.contains('hl-mvp')) {"
        js .= "          span.setAttribute('data-mvp-idx', transSpansArray.length);"
        js .= "          span.setAttribute('data-mvp-type', 'trans');"
        js .= "          transSpansArray.push(span);"
        js .= "        }"
        js .= "      }"
        js .= "    }"
        js .= "  }"
        js .= "  function getTargetIdx(idx, isSource) {"
        js .= "    var L_src = sourceSpansArray.length;"
        js .= "    var L_tr = transSpansArray.length;"
        js .= "    if (L_src <= 1 || L_tr <= 1) return 0;"
        js .= "    if (isSource) {"
        js .= "      var ratio = idx / (L_src - 1);"
        js .= "      return Math.round(ratio * (L_tr - 1));"
        js .= "    } else {"
        js .= "      var ratio = idx / (L_tr - 1);"
        js .= "      return Math.round(ratio * (L_src - 1));"
        js .= "    }"
        js .= "  }"
        js .= "  function wireEvents() {"
        js .= "    var ensureIndex = function() {"
        js .= "      if (!isIndexBuilt) buildLcIndex();"
        js .= "    };"
        js .= "    var handleMouseOver = function() {"
        js .= "      if (window.__selectableTextMode) return;"
        js .= "      ensureIndex();"
        js .= "      var idxStr = this.getAttribute('data-mvp-idx');"
        js .= "      if (idxStr !== null && idxStr !== '') {"
        js .= "        var idx = parseInt(idxStr, 10);"
        js .= "        var isSource = (this.getAttribute('data-mvp-type') === 'source');"
        js .= "        var targetIdx = getTargetIdx(idx, isSource);"
        js .= "        var targetSpan = isSource ? transSpansArray[targetIdx] : sourceSpansArray[targetIdx];"
        js .= "        if (targetSpan) {"
        js .= "          addClass(targetSpan, 'hl-mvp-hover');"
        js .= "        }"
        js .= "      }"
        js .= "    };"
        js .= "    var handleMouseOut = function() {"
        js .= "      if (window.__selectableTextMode) return;"
        js .= "      ensureIndex();"
        js .= "      var idxStr = this.getAttribute('data-mvp-idx');"
        js .= "      if (idxStr !== null && idxStr !== '') {"
        js .= "        var idx = parseInt(idxStr, 10);"
        js .= "        var isSource = (this.getAttribute('data-mvp-type') === 'source');"
        js .= "        var targetIdx = getTargetIdx(idx, isSource);"
        js .= "        var targetSpan = isSource ? transSpansArray[targetIdx] : sourceSpansArray[targetIdx];"
        js .= "        if (targetSpan && !targetSpan.classList.contains('hl-mvp-pin')) {"
        js .= "          removeClass(targetSpan, 'hl-mvp-hover');"
        js .= "        }"
        js .= "      }"
        js .= "    };"
        js .= "    var handleClick = function(e) {"
        js .= "      if (window.__selectableTextMode) return;"
        js .= "      ensureIndex();"
        js .= "      e = e || window.event;"
        js .= "      var btn = (e.button !== undefined) ? e.button : e.which;"
        js .= "      if (btn !== 0 && btn !== 1) return;"
        js .= "      var idxStr = this.getAttribute('data-mvp-idx');"
        js .= "      if (idxStr === null || idxStr === '') return;"
        js .= "      var idx = parseInt(idxStr, 10);"
        js .= "      var isSource = (this.getAttribute('data-mvp-type') === 'source');"
        js .= "      var bKey = (isSource ? 's' : 't') + idxStr;"
        js .= "      var bIdx = -1;"
        js .= "      for (var i = 0; i < bookmarks.length; i++) {"
        js .= "        if (bookmarks[i].idx === bKey) { bIdx = i; break; }"
        js .= "      }"
        js .= "      var targetIdx = getTargetIdx(idx, isSource);"
        js .= "      var srcSpan = isSource ? sourceSpansArray[idx] : sourceSpansArray[targetIdx];"
        js .= "      var transSpan = isSource ? transSpansArray[targetIdx] : transSpansArray[idx];"
        js .= "      if (bIdx !== -1) {"
        js .= "        if (srcSpan) { removeClass(srcSpan, 'hl-mvp-pin'); removeClass(srcSpan, 'hl-mvp-hover'); }"
        js .= "        if (transSpan) { removeClass(transSpan, 'hl-mvp-pin'); removeClass(transSpan, 'hl-mvp-hover'); }"
        js .= "        bookmarks.splice(bIdx, 1);"
        js .= "      } else {"
        js .= "        if (srcSpan) addClass(srcSpan, 'hl-mvp-pin');"
        js .= "        if (transSpan) addClass(transSpan, 'hl-mvp-pin');"
        js .= "        bookmarks.push({ idx: bKey, srcSpan: srcSpan, transSpan: transSpan });"
        js .= "        if (bookmarks.length > N) {"
        js .= "          var oldest = bookmarks.shift();"
        js .= "          if (oldest.srcSpan) removeClass(oldest.srcSpan, 'hl-mvp-pin');"
        js .= "          if (oldest.transSpan) removeClass(oldest.transSpan, 'hl-mvp-pin');"
        js .= "        }"
        js .= "      }"
        js .= "    };"
        js .= "    var handleSelectStart = function(e) {"
        js .= "      if (window.__selectableTextMode) return true;"
        js .= "      e = e || window.event;"
        js .= "      if (e.preventDefault) e.preventDefault();"
        js .= "      if (e.returnValue !== undefined) e.returnValue = false;"
        js .= "      return false;"
        js .= "    };"
        js .= "    var sc = document.getElementById('source-container');"
        js .= "    if (sc) {"
        js .= "      var srcSpans = sc.getElementsByTagName('span');"
        js .= "      for (var i = 0; i < srcSpans.length; i++) {"
        js .= "        var span = srcSpans[i];"
        js .= "        if (span.classList && span.classList.contains('word')) {"
        js .= "          if (span.getAttribute('data-mvp-wired')) continue;"
        js .= "          span.setAttribute('data-mvp-wired', '1');"
        js .= "          addEvent(span, 'mouseover', handleMouseOver);"
        js .= "          addEvent(span, 'mouseout', handleMouseOut);"
        js .= "          addEvent(span, 'click', handleClick);"
        js .= "          addEvent(span, 'selectstart', handleSelectStart);"
        js .= "        }"
        js .= "      }"
        js .= "    }"
        js .= "    var tc = document.getElementById('translation-container');"
        js .= "    if (tc) {"
        js .= "      var transSpans = tc.getElementsByTagName('span');"
        js .= "      for (var j = 0; j < transSpans.length; j++) {"
        js .= "        var span = transSpans[j];"
        js .= "        if (span.classList && span.classList.contains('hl-mvp')) {"
        js .= "          if (span.getAttribute('data-mvp-wired')) continue;"
        js .= "          span.setAttribute('data-mvp-wired', '1');"
        js .= "          addEvent(span, 'mouseover', handleMouseOver);"
        js .= "          addEvent(span, 'mouseout', handleMouseOut);"
        js .= "          addEvent(span, 'click', handleClick);"
        js .= "          addEvent(span, 'selectstart', handleSelectStart);"
        js .= "        }"
        js .= "      }"
        js .= "    }"
        js .= "  }"
        js .= "  window.clearMVPBookmarks = function() {"
        js .= "    var cleared = false;"
        js .= "    if (bookmarks && bookmarks.length > 0) {"
        js .= "      cleared = true;"
        js .= "      for (var i = 0; i < bookmarks.length; i++) {"
        js .= "        var entry = bookmarks[i];"
        js .= "        try {"
        js .= "          if (entry.srcSpan && isAttached(entry.srcSpan)) {"
        js .= "            removeClass(entry.srcSpan, 'hl-mvp-pin');"
        js .= "            removeClass(entry.srcSpan, 'hl-mvp-hover');"
        js .= "          }"
        js .= "        } catch(e) {}"
        js .= "        try {"
        js .= "          if (entry.transSpan && isAttached(entry.transSpan)) {"
        js .= "            removeClass(entry.transSpan, 'hl-mvp-pin');"
        js .= "            removeClass(entry.transSpan, 'hl-mvp-hover');"
        js .= "          }"
        js .= "        } catch(e) {}"
        js .= "      }"
        js .= "      bookmarks = [];"
        js .= "    }"
        js .= "    return cleared;"
        js .= "  };"
        js .= "  window.getBookmarkIndices = function() {"
        js .= "    var indices = [];"
        js .= "    if (bookmarks) {"
        js .= "      for (var i = 0; i < bookmarks.length; i++) {"
        js .= "        indices.push(bookmarks[i].idx);"
        js .= "      }"
        js .= "    }"
        js .= "    return indices.join(',');"
        js .= "  };"
        js .= "  window.restoreBookmarksByIndices = function(indicesStr) {"
        js .= "    bookmarks = [];"
        js .= "    if (!indicesStr) return;"
        js .= "    var indices = indicesStr.split(',');"
        js .= "    if (!isIndexBuilt) buildLcIndex();"
        js .= "    for (var i = 0; i < indices.length; i++) {"
        js .= "      var bKey = indices[i];"
        js .= "      if (bKey === '') continue;"
        js .= "      var prefix = bKey.charAt(0);"
        js .= "      var idx, isSource;"
        js .= "      if (prefix === 's' || prefix === 't') {"
        js .= "        idx = parseInt(bKey.substring(1), 10);"
        js .= "        isSource = (prefix === 's');"
        js .= "      } else {"
        js .= "        idx = parseInt(bKey, 10);"
        js .= "        isSource = true;"
        js .= "      }"
        js .= "      var targetIdx = getTargetIdx(idx, isSource);"
        js .= "      var srcSpan = isSource ? sourceSpansArray[idx] : sourceSpansArray[targetIdx];"
        js .= "      var transSpan = isSource ? transSpansArray[targetIdx] : transSpansArray[idx];"
        js .= "      if (srcSpan) addClass(srcSpan, 'hl-mvp-pin');"
        js .= "      if (transSpan) addClass(transSpan, 'hl-mvp-pin');"
        js .= "      bookmarks.push({ idx: bKey, srcSpan: srcSpan, transSpan: transSpan });"
        js .= "    }"
        js .= "  };"
        js .= "  addEvent(document, 'keydown', function(e) {"
        js .= "    e = e || window.event;"
        js .= "    var code = e.keyCode || e.which;"
        js .= "    if (code === 27 || e.key === 'Escape') {"
        js .= "      window.clearMVPBookmarks();"
        js .= "    }"
        js .= "  });"
        js .= "  window.setSelectableTextMode = function(active) {"
        js .= "    window.__selectableTextMode = !!active;"
        js .= "    if (active) {"
        js .= "      addClass(document.body, 'text-selection-mode-active');"
        js .= "    } else {"
        js .= "      removeClass(document.body, 'text-selection-mode-active');"
        js .= "    }"
        js .= "  };"
        js .= "  window.setSelectableTextMode(" (guiObj.selectableTextMode ? "true" : "false") ");"
        js .= "  setTimeout(function() {"
        js .= "    window.rebindMVPBookmarks = function() {"
        js .= "      tokenizeTranslation();"
        js .= "      buildLcIndex();"
        js .= "      wireEvents();"
        js .= "    };"
        js .= "    window.rebindMVPBookmarks();"
        js .= "  }, 50);"
        js .= "  } catch(err) {"
        js .= "    if (window.ahkCall) {"
        js .= "      window.ahkCall('JS_Error', err.name + ': ' + err.message + ' at ' + (err.stack || 'no stack'));"
        js .= "    } else {"
        js .= "      alert('JS Error: ' + err.message);"
        js .= "    }"
        js .= "  }"
        js .= "})();"

        scriptEl.text := js
        doc.body.appendChild(scriptEl)
    } catch Any as e {
        MsgBox("Injection failed: " e.Message "`nLine: " e.Line "`nFile: " e.File, "Kardenwort Error", 16)
    }
}
