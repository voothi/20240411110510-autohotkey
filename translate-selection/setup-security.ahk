#Requires AutoHotkey v2.0
#Include ..\Lib\Security.ahk

; ==============================================================================
; Security Setup & Management Script
; ==============================================================================
; Usage:
;   Run this script to configure or update your secure API keys.
;   To add a NEW key:
;     1. Add a new `ConfigureKey(...)` line below in the "Keys to Manage" section.
;     2. Update your main script to retrieve it using `Security.Deobfuscate(...)`.
; ==============================================================================

; --- Configuration ---
ConfigName := "settings.ini"
SecretsFileName := "secrets.ini"

; --- Initialization ---
; Assuming settings.ini is in the same directory
SettingsPath := A_ScriptDir . "\" . ConfigName
UserProfile := EnvGet("USERPROFILE")
DefaultSecretsDir := UserProfile . "\.translate-selection"
DefaultSecretsFile := DefaultSecretsDir . "\" . SecretsFileName

; Load Settings
CurrentSalt := IniRead(SettingsPath, "Security", "Salt", "")
CurrentSecretsPath := IniRead(SettingsPath, "Security", "SecretsPath", "")

; 1. Ensure Salt Exists
if (CurrentSalt == "") {
    ib := InputBox("Enter a salt string for obfuscation (leave empty to generate random):", "Setup Security - Step 1/2",
        "w400 h150")
    if (ib.Result == "Cancel")
        ExitApp

    CurrentSalt := ib.Value
    if (CurrentSalt == "") {
        CurrentSalt := RandomString(16)
    }
    IniWrite(CurrentSalt, SettingsPath, "Security", "Salt")
}

; 2. Ensure Secrets Path Exists
if (CurrentSecretsPath == "") {
    CurrentSecretsPath := DefaultSecretsFile
    ; Optional: Prompt for custom location could go here
    IniWrite(CurrentSecretsPath, SettingsPath, "Security", "SecretsPath")
}

; Create User Profile Directory if needed
SplitPath CurrentSecretsPath, , &OutDir
if !DirExist(OutDir)
    DirCreate OutDir

; ==============================================================================
; Keys to Manage
; ==============================================================================

ConfigureKey("DeepL", "Key", "DeepL API Key")

; Example of adding a new one:
; ConfigureKey("OpenAI", "Key", "OpenAI API Token")

MsgBox "Security configuration check complete!", "Done", 64

; ==============================================================================
; Helper Functions
; ==============================================================================

ConfigureKey(Section, KeyName, DisplayName) {
    global CurrentSecretsPath, CurrentSalt

    ; 1. Check for local migration opportunity (Legacy)
    ; Assuming secrets.ini might be in same dir if legacy
    LocalSecretsFile := A_ScriptDir . "\secrets.ini"
    MigratedValue := ""

    if FileExist(LocalSecretsFile) {
        Val := IniRead(LocalSecretsFile, Section, KeyName, "")
        if (Val != "") {
            if (MsgBox("Found local " . DisplayName . " in secrets.ini.`nMigrate and Secure it?", "Migrate", 36) ==
            "Yes") {
                MigratedValue := Val
            }
        }
    }

    ; 2. Check if already exists in secure storage
    ExistingObfuscated := IniRead(CurrentSecretsPath, Section, KeyName, "")
    NewValue := ""

    if (MigratedValue != "") {
        NewValue := MigratedValue
    } else if (ExistingObfuscated != "") {
        ; Already exists. Ask to update.
        if (MsgBox(DisplayName . " is already configured.`nDo you want to overwrite it?", "Update Key", 36) == "Yes") {
            ib := InputBox("Enter new " . DisplayName . ":", "Update " . DisplayName)
            if (ib.Result == "OK")
                NewValue := ib.Value
        }
    } else {
        ; Doesn't exist. Ask to set.
        ib := InputBox("Enter " . DisplayName . ":", "Setup " . DisplayName)
        if (ib.Result == "OK")
            NewValue := ib.Value
    }

    ; 3. Write if we have a new value
    if (NewValue != "") {
        Obfuscated := Security.Obfuscate(NewValue, CurrentSalt)
        IniWrite(Obfuscated, CurrentSecretsPath, Section, KeyName)
        MsgBox(DisplayName . " secured successfully.")
    }
}

RandomString(length) {
    chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    str := ""
    loop length {
        rand := Random(1, StrLen(chars))
        str .= SubStr(chars, rand, 1)
    }
    return str
}
