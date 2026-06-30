#Requires AutoHotkey v2.0
#SingleInstance Off

#Include ..\Lib\ClipboardUtil.ahk
#Include ..\Lib\B64Util.ahk

; ===================================================================================
; Configuration & Globals
; ===================================================================================
global G_DeskPythonPath := ""
global G_DeskScriptPath := ""
global G_DefaultLanguage := "en"
global G_CurrentLang := "en"
global G_FileWatcherIntervalMs := 1000
global G_MultiTapTimeout := 300
global G_TapSingleMode := "single"
global G_TapDoubleMode := "multi"
global G_OrdinaryColor := "#ffd700"
global G_PairedColor := "#9370db"
global G_DefaultZoom := "100"

global G_PressCount := 0
global G_CapturedText := ""
global G_WindowCount := 0
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
    global G_MultiTapTimeout := IniRead(configPath, "Settings", "MultiTapTimeout", 300)
    global G_TapSingleMode := IniRead(configPath, "Hotkey", "TapSingleMode", "single")
    global G_TapDoubleMode := IniRead(configPath, "Hotkey", "TapDoubleMode", "multi")
    global G_OrdinaryColor := IniRead(configPath, "Highlight", "OrdinaryColor", "#ffd700")
    global G_PairedColor := IniRead(configPath, "Highlight", "PairedColor", "#9370db")
    global G_DefaultZoom := IniRead(configPath, "Settings", "DefaultZoom", "100")

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
    RegExMatch(fileName, "\.([a-z]{2})\.tsv$", &mLang)
    if (mLang) {
        lang := mLang[1]
    }

    global G_CurrentLang := lang
    UpdateTrayMenu()
    UpdateTrayIcon()

    LaunchKardenwortWindow(sourceText, "multi", ZID)
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
    global G_WindowCount
    x := 50 + G_WindowCount * 30
    y := 50 + G_WindowCount * 30
    G_WindowCount := Mod(G_WindowCount + 1, 15)
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
    ZID := presetZID != "" ? presetZID : A_Now "_" A_TickCount
    lang := G_CurrentLang

    guiTitle := "Kardenwort - " lang " (" textMode ")"
    GetCascadeCoords(&x, &y)

    ; Create GUI
    MyGui := Gui("+Resize +MinSize400x300", guiTitle)
    MyGui.OnEvent("Close", GuiClose)
    MyGui.OnEvent("Size", GuiSize)

    ; ActiveX Explorer
    wvc := MyGui.Add("ActiveX", "x10 y10 w800 h600", "Shell.Explorer")
    wb := wvc.Value

    ; Native Footer Buttons
    SaveBtn := MyGui.Add("Button", "x15 y615 w100 h30 Disabled", "Save (Ctrl+S)")
    SendBtn := MyGui.Add("Button", "x125 y615 w120 h30", "Send to Anki")
    StatusTxt := MyGui.Add("Text", "x255 y620 w540 h25", "Ready")

    ; Store references on GUI object
    MyGui.wb := wb
    MyGui.wvc := wvc
    MyGui.SaveBtn := SaveBtn
    MyGui.SendBtn := SendBtn
    MyGui.StatusTxt := StatusTxt
    MyGui.ZID := ZID
    MyGui.Lang := lang
    MyGui.TextMode := textMode
    MyGui.SourceText := sourceText
    MyGui.TsvPath := ""
    MyGui.LastMTime := ""

    SaveBtn.OnEvent("Click", OnSaveClick.Bind(MyGui))
    SendBtn.OnEvent("Click", OnSendToAnkiClick.Bind(MyGui))

    MyGui.Show("x" x " y" y " w830 h660")

    ; Fetch HTML from Python core
    StatusTxt.Text := "Invoking backend analysis..."

    tmpTextFile := A_Temp "\karden_input_" ZID ".txt"
    try {
        FileAppend(sourceText, tmpTextFile, "UTF-8")
    } catch as e {
        StatusTxt.Text := "Input write failed"
        MsgBox("Failed to write temporary text input:`n" e.Message, "Kardenwort Error", 16)
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" render --language ' lang ' --zid ' ZID ' --text-mode ' textMode ' < "' tmpTextFile '"'
    exitCode := RunSilent(cmd, &outB64, &errJSON)
    try {
        FileDelete(tmpTextFile)
    } catch {
    }

    if (exitCode != 0) {
        StatusTxt.Text := "Analysis failed"
        MsgBox("Kardenwort Analysis failed:`n" errJSON, "Kardenwort Error", 16)
        MyGui.Destroy()
        return
    }

    StatusTxt.Text := "Rendering..."
    htmlContent := B64Decode(outB64)

    wb.Navigate("about:blank")
    while wb.ReadyState != 4
        Sleep(10)
    wb.document.write(htmlContent)
    wb.document.close()
    ApplyZoom(wb)

    ; Bind callback for bidirectional updates and dirty flag
    wb.document.parentWindow.ahkCall := OnAhkCall.Bind(MyGui)

    ; Retrieve metadata from HTML DOM
    try {
        tsvPath := wb.document.getElementById("tsv-path").innerText
        MyGui.TsvPath := tsvPath
        if FileExist(tsvPath) {
            MyGui.LastMTime := FileGetTime(tsvPath)
        }

        ; Start polling file watcher
        if (G_FileWatcherIntervalMs > 0) {
            MyGui.TimerFn := WatchFile.Bind(MyGui)
            SetTimer(MyGui.TimerFn, G_FileWatcherIntervalMs)
        }
        StatusTxt.Text := "Analysis loaded successfully"
    } catch {
        StatusTxt.Text := "Metadata binding failed"
    }
}

OnAhkCall(guiObj, action, value) {
    if (action == "dirty") {
        if (value == "true") {
            guiObj.SaveBtn.Enabled := true
            guiObj.StatusTxt.Text := "Unsaved edits"
        } else {
            guiObj.SaveBtn.Enabled := false
            guiObj.StatusTxt.Text := "Edits saved"
        }
    }
}

OnSaveClick(guiObj, *) {
    guiObj.StatusTxt.Text := "Saving..."

    ; Retrieve deltas
    try {
        deltasJSON := guiObj.wb.document.parentWindow.getDeltas()
    } catch as e {
        MsgBox("Failed to retrieve deltas from page: " e.Message, "Kardenwort Error", 16)
        return
    }

    tmpDeltasFile := A_Temp "\karden_deltas_" guiObj.ZID ".json"
    try {
        FileAppend(deltasJSON, tmpDeltasFile, "UTF-8")
    } catch as e {
        guiObj.StatusTxt.Text := "Deltas write failed"
        MsgBox("Failed to write temporary delta file: " e.Message, "Kardenwort Error", 16)
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" edit-save --deltas "' tmpDeltasFile '" --zid ' guiObj.ZID ' --language ' guiObj
        .Lang
    exitCode := RunSilent(cmd, &outStr, &errJSON)
    try {
        FileDelete(tmpDeltasFile)
    } catch {
    }

    if (exitCode == 0 && InStr(outStr, "SUCCESS")) {
        guiObj.wb.document.parentWindow.clearDirty()
        guiObj.SaveBtn.Enabled := false
        guiObj.StatusTxt.Text := "Edits saved successfully"
        if FileExist(guiObj.TsvPath) {
            guiObj.LastMTime := FileGetTime(guiObj.TsvPath)
        }
    } else {
        guiObj.StatusTxt.Text := "Save failed"
        MsgBox("Failed to save cell edits:`n" errJSON, "Kardenwort Error", 16)
    }
}

OnSendToAnkiClick(guiObj, *) {
    guiObj.StatusTxt.Text := "Exporting favorites..."

    try {
        selectedRowsJSON := guiObj.wb.document.parentWindow.getSelectedRows()
    } catch {
        selectedRowsJSON := "[]"
    }

    manifest := '{"selected_row_ids": ' selectedRowsJSON ', "zid": "' guiObj.ZID '"}'
    tmpManifestFile := A_Temp "\karden_manifest_" guiObj.ZID ".json"
    try {
        FileAppend(manifest, tmpManifestFile, "UTF-8")
    } catch as e {
        guiObj.StatusTxt.Text := "Manifest write failed"
        MsgBox("Failed to write temporary manifest file: " e.Message, "Kardenwort Error", 16)
        return
    }

    cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" export --selection-manifest "' tmpManifestFile '" --language ' guiObj
        .Lang
    exitCode := RunSilent(cmd, &outStr, &errJSON)
    try {
        FileDelete(tmpManifestFile)
    } catch {
    }

    if (exitCode == 0) {
        if (SubStr(Trim(outStr), 1, 1) == "{") {
            RegExMatch(outStr, '"import_started":\s*(\w+)', &mStarted)
            RegExMatch(outStr, '"log":\s*"([^"]+)"', &mLog)
            if (mStarted && mStarted[1] == "true") {
                guiObj.StatusTxt.Text := "Import started in background"
                logPath := mLog ? mLog[1] : "log file next to TSV"
                MsgBox("Favorites exported successfully!`nAnki import started in background.`n`nLog: " logPath "`n`nYou can safely close this window now.",
                    "Kardenwort", 64)
                return
            }
        }
        guiObj.StatusTxt.Text := "Exported successfully"
        MsgBox("Favorites exported successfully!`nOutput: " outStr, "Kardenwort", 64)
    } else {
        guiObj.StatusTxt.Text := "Export failed"
        MsgBox("Failed to export favorites:`n" errJSON, "Kardenwort Error", 16)
    }
}

WatchFile(guiObj) {
    try {
        hwnd := guiObj.Hwnd
    } catch {
        hwnd := 0
    }
    if (hwnd == 0 || !WinExist("ahk_id " hwnd)) {
        if (guiObj.HasOwnProp("TimerFn")) {
            SetTimer(guiObj.TimerFn, 0)
        }
        return
    }

    tsvPath := guiObj.TsvPath
    if (tsvPath == "" || !FileExist(tsvPath))
        return

    try {
        currentMTime := FileGetTime(tsvPath)
    } catch {
        return
    }

    if (currentMTime != guiObj.LastMTime) {
        guiObj.LastMTime := currentMTime

        isDirty := false
        try {
            isDirty := guiObj.wb.document.parentWindow.isDirty()
        } catch {
        }

        if (isDirty) {
            res := MsgBox("The working TSV was modified externally. Reload and discard your unsaved edits?",
                "Kardenwort", "YesNo Icon!")
            if (res == "No") {
                return
            }
        }

        guiObj.StatusTxt.Text := "Reloading..."

        tmpTextFile := A_Temp "\karden_input_" guiObj.ZID ".txt"
        try {
            FileAppend(guiObj.SourceText, tmpTextFile, "UTF-8")
        } catch {
            return
        }

        cmd := '"' G_DeskPythonPath '" "' G_DeskScriptPath '" render --language ' guiObj.Lang ' --zid ' guiObj.ZID ' --text-mode ' guiObj
            .TextMode ' < "' tmpTextFile '"'
        exitCode := RunSilent(cmd, &outB64, &errJSON)
        try {
            FileDelete(tmpTextFile)
        } catch {
        }

        if (exitCode == 0) {
            htmlContent := B64Decode(outB64)
            guiObj.wb.Navigate("about:blank")
            while guiObj.wb.ReadyState != 4
                Sleep(10)
            guiObj.wb.document.write(htmlContent)
            guiObj.wb.document.close()
            ApplyZoom(guiObj.wb)
            guiObj.wb.document.parentWindow.ahkCall := OnAhkCall.Bind(guiObj)
            guiObj.StatusTxt.Text := "Reloaded successfully"
        } else {
            guiObj.StatusTxt.Text := "Reload failed"
        }
    }
}

GuiClose(thisGui) {
    isDirty := false
    try {
        isDirty := thisGui.wb.document.parentWindow.isDirty()
    } catch {
    }

    if (isDirty) {
        res := MsgBox("You have unsaved edits. Save changes before closing?", "Kardenwort", "YesNoCancel Icon!")
        if (res == "Yes") {
            OnSaveClick(thisGui)
            try {
                if (thisGui.wb.document.parentWindow.isDirty()) {
                    return true
                }
            } catch {
            }
        } else if (res == "Cancel") {
            return true
        }
    }

    if (thisGui.HasOwnProp("TimerFn")) {
        SetTimer(thisGui.TimerFn, 0)
    }
    thisGui.wb := ""
    thisGui.Destroy()

    global G_WindowCount
    G_WindowCount := Max(0, G_WindowCount - 1)
}

GuiSize(thisGui, MinMax, Width, Height) {
    if (MinMax == -1)
        return
    thisGui.wvc.Move(, , Width - 20, Height - 65)
    btnY := Height - 40
    thisGui.SaveBtn.Move(15, btnY)
    thisGui.SendBtn.Move(125, btnY)
    thisGui.StatusTxt.Move(255, btnY + 5, Width - 270)
}

; ===================================================================================
; Hotkey & SmartAction Routing
; ===================================================================================
HandleSmartAction() {
    global G_PressCount, G_CapturedText, G_TapSingleMode, G_TapDoubleMode
    Taps := G_PressCount
    G_PressCount := 0

    textMode := G_TapSingleMode
    if (Taps == 2) {
        textMode := G_TapDoubleMode
    }

    ; Release Alt, Control, and Shift to avoid Modifier Bleed
    KeyWait "Alt"
    KeyWait "Control"
    KeyWait "Shift"

    LaunchKardenwortWindow(G_CapturedText, textMode)
}

; Register global hotkey Ctrl+Alt+Shift+D
^+!d::
{
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

; Register GUI hotkey Ctrl+S for saving in active Kardenwort windows
#HotIf WinActive("Kardenwort - ")
^s:: {
    activeHwnd := WinActive("A")
    if (activeHwnd) {
        guiObj := GuiFromHwnd(activeHwnd)
        if (guiObj) {
            OnSaveClick(guiObj)
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
