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

; ==============================================================================
; Keys to Manage
; ==============================================================================
ManagedKeys := [{ Section: "DeepL", Key: "Key", Name: "DeepL API Key" }]

; ==============================================================================
; Main Menu
; ==============================================================================
Result := MsgBox(
    "Choose an action:`n`n[Yes] Interactive Configuration (Add/Update)`n[No] Advanced: Bulk Encrypt/Decrypt File",
    "Security Manager", 3)

if (Result == "Yes") {
    for Item in ManagedKeys {
        ConfigureKey(Item.Section, Item.Key, Item.Name)
    }
} else if (Result == "No") {
    Action := MsgBox("Advanced Mode:`n`n[Yes] Encrypt all keys in file`n[No] Decrypt all keys in file (to plain text)",
        "Bulk Action", 3)

    if (Action == "Yes") {
        BulkProcess("Encrypt")
    } else if (Action == "No") {
        BulkProcess("Decrypt")
    }
}

MsgBox "Security configuration check complete!", "Done", 64

; ==============================================================================
; Helper Functions
; ==============================================================================

BulkProcess(Mode) {
    global CurrentSecretsPath, CurrentSalt, ManagedKeys

    Count := 0
    for Item in ManagedKeys {
        Val := IniRead(CurrentSecretsPath, Item.Section, Item.Key, "")
        if (Val == "")
            continue

        NewVal := ""

        ; Verify if currently encrypted by attempting to decrypt and finding the marker
        TempDecrypted := Security.Deobfuscate(Val, CurrentSalt)
        IsEncrypted := (SubStr(TempDecrypted, 1, 7) == "%%SEC%%")

        if (Mode == "Encrypt") {
            if (!IsEncrypted) {
                ; Encrypt plain text with Magic Marker
                ; We prepend %%SEC%% so we can verify it later
                Obfuscated := Security.Obfuscate("%%SEC%%" . Val, CurrentSalt)
                NewVal := Obfuscated
                Count++
            }
        } else if (Mode == "Decrypt") {
            if (IsEncrypted) {
                ; Decrypt to plain text (stripped of marker)
                NewVal := SubStr(TempDecrypted, 8)
                Count++
            }
        }

        if (NewVal != "") {
            IniWrite(NewVal, CurrentSecretsPath, Item.Section, Item.Key)
        }
    }

    if (Count > 0)
        MsgBox(Mode . "ion complete. Processed " . Count . " keys.`nFile: " . CurrentSecretsPath)
    else
        MsgBox("No keys needed " . Mode . "ion (All items were already up to date).")
}

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
        ; Check if it is already encrypted (Internal Magic Marker Check)
        DecryptedCheck := Security.Deobfuscate(ExistingObfuscated, CurrentSalt)
        IsEncrypted := (SubStr(DecryptedCheck, 1, 7) == "%%SEC%%")

        if (IsEncrypted) {
            ; Already secure. Ask to update/overwrite.
            if (MsgBox(DisplayName . " is already secured.`nDo you want to overwrite it?", "Update Key", 36) == "Yes") {
                ib := InputBox("Enter new " . DisplayName . ":", "Update " . DisplayName)
                if (ib.Result == "OK")
                    NewValue := Trim(ib.Value)
            }
        } else {
            ; Exists but is NOT encrypted (Plain Text in secure file).
            ; Ask to encrypt it.
            if (MsgBox("Found plain text " . DisplayName . " in secure storage.`nEncrypt it now?", "Secure Key", 36) ==
            "Yes") {
                NewValue := ExistingObfuscated
            }
        }
    } else {
        ; Doesn't exist. Ask to set.
        ib := InputBox("Enter " . DisplayName . ":", "Setup " . DisplayName)
        if (ib.Result == "OK")
            NewValue := Trim(ib.Value)
    }

    ; 3. Write if we have a new value
    if (NewValue != "") {
        ; Prepend Marker before encrypting
        Obfuscated := Security.Obfuscate("%%SEC%%" . NewValue, CurrentSalt)
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
