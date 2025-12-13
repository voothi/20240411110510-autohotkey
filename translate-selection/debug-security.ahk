#Requires AutoHotkey v2.0
#Include ..\Lib\Security.ahk

; ==============================================================================
; Debug Security Script
; ==============================================================================
; Run this to see EXACTLY what the system sees when it tries to read your key.
; ==============================================================================

ConfigName := "settings.ini"
SettingsPath := A_ScriptDir . "\" . ConfigName

; 1. Load Settings
CurrentSalt := IniRead(SettingsPath, "Security", "Salt", "")
CurrentSecretsPath := IniRead(SettingsPath, "Security", "SecretsPath", "")

if (CurrentSalt == "") {
    MsgBox("Error: No Salt found in settings.ini")
    ExitApp
}
if (CurrentSecretsPath == "") {
    ; Fallback logic from main script
    CurrentSecretsPath := EnvGet("USERPROFILE") . "\.translate-selection\secrets.ini"
}

if !FileExist(CurrentSecretsPath) {
    MsgBox("Error: Secrets file not found at:`n" . CurrentSecretsPath)
    ExitApp
}

; 2. Read Key
ObfuscatedKey := IniRead(CurrentSecretsPath, "DeepL", "Key", "")

if (ObfuscatedKey == "") {
    MsgBox("Error: Key 'DeepL' found but empty in secrets file.")
    ExitApp
}

; 3. Attempt Decrypt
Decrypted := Security.Deobfuscate(ObfuscatedKey, CurrentSalt)

; 4. Analyze
IsEncryptedMatches := (SubStr(Decrypted, 1, 7) == "%%SEC%%")
ExtractedKey := SubStr(Decrypted, 8)

Report := "DEBUG REPORT`n"
Report .= "--------------------------------------------------`n"
Report .= "Secrets File: " . CurrentSecretsPath . "`n"
Report .= "Salt (First 3 chars): " . SubStr(CurrentSalt, 1, 3) . "***`n"
Report .= "--------------------------------------------------`n"
Report .= "Raw Value in File (First 10 chars): " . SubStr(ObfuscatedKey, 1, 10) . "...`n"
Report .= "--------------------------------------------------`n"
Report .= "Decrypted Raw: [" . Decrypted . "]`n"
Report .= "Starts with %%SEC%%?: " . (IsEncryptedMatches ? "YES" : "NO") . "`n"
Report .= "--------------------------------------------------`n"

if (IsEncryptedMatches) {
    Report .= "FINAL DECISION: ENCRYPTED`n"
    Report .= "Extracted Key: [" . ExtractedKey . "]`n"
} else {
    Report .= "FINAL DECISION: PLAIN TEXT`n"
    Report .= "Key Used: [" . ObfuscatedKey . "]`n"
}

MsgBox(Report)
; Gui() is not a direct function in v2 for simple alerts. MsgBox is sufficient.
; A_Clipboard := Report
A_Clipboard := Report
MsgBox("Report copied to clipboard.")