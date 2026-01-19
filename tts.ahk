#Requires AutoHotkey v2.0

; ===================================================================================
; Script:       Text-to-Speech (TTS) Hotkeys
;
; Description:  This script provides multi-language Text-to-Speech functionality for
;               any selected text. It utilizes a configuration file (tts_config.ini)
;               for dynamic language and path settings.
;
; Features:
;   - Dynamic Tray Icon: Draws current language code on the tray icon.
;   - Mouse Trigger: Middle Click while Left Click is held (selection) triggers TTS.
;   - Configurable: Languages, colors, hotkeys, and paths are stored in tts_config.ini.
;
; Related Repository: https://github.com/voothi/20260119103526-anki-tts-cli
; ===================================================================================

; --- Initialization & Config Loading ---
configFile := A_ScriptDir "\tts_config.ini"

if !FileExist(configFile) {
    MsgBox("Configuration file not found: " configFile "`nPlease create it based on the template.", "TTS Error", "Icon!")
    ExitApp()
}

; Load Paths
global pythonPath := IniRead(configFile, "Paths", "PythonPath", "python.exe")
global scriptPath := IniRead(configFile, "Paths", "ScriptPath", "")

; Load Settings
global currentLang := IniRead(configFile, "Settings", "DefaultLanguage", "en")
global currentHIcon := 0

; Load Languages and Setup Hotkeys
global langInfo := Map()
try {
    langSection := IniRead(configFile, "Languages")
    for line in StrSplit(langSection, "`n") {
        if (line = "" || InStr(line, ";") == 1)
            continue
        parts := StrSplit(line, "=")
        code := Trim(parts[1])
        vals := StrSplit(parts[2], ",")
        
        info := {
            text: Trim(vals[1]), 
            bg: Number(Trim(vals[2])), 
            fg: Number(Trim(vals[3])), 
            hotkey: vals.Length >= 4 ? Trim(vals[4]) : ""
        }
        langInfo[code] := info
        
        ; Register dynamic hotkeys
        if (info.hotkey != "") {
            Hotkey(info.hotkey, RunPythonScript.Bind(code))
        }
    }
} catch Any as e {
    MsgBox("Error parsing [Languages] section in tts_config.ini:`n" e.Message, "Config Error", "Icon!")
}

; Update Tray Menu to show current language
UpdateTrayMenu() {
    global currentLang, langInfo
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Current Language: " . currentLang, (*) => 0)
    A_TrayMenu.Disable("1&")
    A_TrayMenu.Add() ; Separator
    
    for code, info in langInfo {
        A_TrayMenu.Add(info.text " (" code ")", ((c, *) => SetLanguage(c)).Bind(code))
    }
    
    A_TrayMenu.Add() ; Separator
    A_TrayMenu.AddStandard()
    
    UpdateTrayIcon()
}

SetLanguage(lang) {
    global currentLang := lang
    UpdateTrayMenu()
}

UpdateTrayIcon() {
    global currentLang, currentHIcon, langInfo
    
    info := langInfo.Has(currentLang) ? langInfo[currentLang] : {text: "??", bg: 0x808080, fg: 0xFFFFFF}
    
    newHIcon := CreateIconFromText(info.text, info.bg, info.fg)
    if (newHIcon) {
        TraySetIcon("HICON:" . newHIcon)
        if (currentHIcon)
            DllCall("DestroyIcon", "Ptr", currentHIcon)
        currentHIcon := newHIcon
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
    
    hFont := DllCall("CreateFont", "Int", -11, "Int", 0, "Int", 0, "Int", 0, "Int", 700, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 3, "UInt", 2, "UInt", 1, "UInt", 34, "Str", "Arial Narrow", "Ptr")
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

; Initial Menu Setup
UpdateTrayMenu()

RunPythonScript(lang := "") {
    global currentLang, pythonPath, scriptPath
    if (lang != "" && lang != 0) {
        currentLang := lang
        UpdateTrayMenu()
    } else {
        lang := currentLang
    }

    ; Step 1: Copy the selected text to the clipboard.
    oldClipboard := A_Clipboard
    A_Clipboard := "" 
    
    Sleep(50) 
    Send("^c")
    
    if !ClipWait(2) {
        A_Clipboard := oldClipboard
        return
    }

    ; Step 2: Execute the external Python TTS script.
    RunWait('"' pythonPath '" "' scriptPath '" "' A_Clipboard '" "' lang '"', "", "Hide")
    
    Sleep(1000)
}

; --- Static Mouse Trigger ---
~LButton & MButton:: {
    RunPythonScript()
}
