#Requires AutoHotkey v2.0
#Include ..\Lib\Security.ahk

; ==============================================================================
; Script:       Security Manager (setup-security.ahk)
; Description:  A GUI utility for managing secure API keys used by the translation system.
;
; Purpose:
;   - Provides a friendly interface to Add, Edit, and View API keys.
;   - Handles encryption (Obfuscation) of keys using a Salt.
;   - Stores encrypted keys in a secure, user-specific location (user_profile/.translate-selection/secrets.ini).
;   - Prevents clear-text keys from being stored in the project directory.
;
; How it Works:
;   1. Reads 'settings.ini' to find the 'Salt' and the path to 'secrets.ini'.
;   2. Lists all managed keys (e.g. DeepL).
;   3. Indicates status:
;      - 🔒 Encrypted: Key is obfuscated with '%%SEC%%' marker. Safe.
;      - ⚠️ Plain Text: Key is raw text. Risky.
;      - ❌ Missing: Key not found.
;   4. Allows Bulk Encryption to secure all plain text keys at once.
;
; Usage:
;   Run this script to configure your keys. You do NOT need to run this for daily translation.
; ==============================================================================

; --- Configuration & Paths ---
ConfigName := "settings.ini"
SecretsFileName := "secrets.ini"
SettingsPath := A_ScriptDir . "\" . ConfigName

; Load Settings / Paths
CurrentSalt := IniRead(SettingsPath, "Security", "Salt", "")
CurrentSecretsPath := IniRead(SettingsPath, "Security", "SecretsPath", "")
UserProfile := EnvGet("USERPROFILE")
DefaultSecretsDir := UserProfile . "\.translate-selection"
DefaultSecretsFile := DefaultSecretsDir . "\" . SecretsFileName

; Ensure defaults if missing
if (CurrentSalt == "") {
    CurrentSalt := RandomString(16)
    IniWrite(CurrentSalt, SettingsPath, "Security", "Salt")
}
if (CurrentSecretsPath == "") {
    CurrentSecretsPath := DefaultSecretsFile
    IniWrite(CurrentSecretsPath, SettingsPath, "Security", "SecretsPath")
}

; Ensure Directory Exists
SplitPath CurrentSecretsPath, , &OutDir
if !DirExist(OutDir)
    DirCreate OutDir

; ==============================================================================
; Main Application
; ==============================================================================
App := SecurityManager()

class SecurityManager {
    ManagedKeys := [{ Section: "DeepL", Key: "Key", Name: "DeepL API Key" }]
    RevealMode := false
    SaltVisible := false

    __New() {
        this.Gui := Gui("+Resize +MinSize600x400", "Security Manager")
        this.Gui.SetFont("s10", "Segoe UI")
        this.Gui.OnEvent("Close", (*) => ExitApp())

        ; Header
        this.Gui.SetFont("Bold")
        this.Gui.Add("Text", "w600", "Secure Storage Location:")
        this.Gui.SetFont("Norm")
        this.Gui.Add("Edit", "w600 ReadOnly vSecretsPath", CurrentSecretsPath)

        this.Gui.Add("Text", "xm y+10 w600", "Encryption Salt:")
        this.SaltEdit := this.Gui.Add("Edit", "w430 ReadOnly Password vSaltDisplay", CurrentSalt)
        this.BtnShowSalt := this.Gui.Add("Button", "x+5 yp w45", "👁")
        this.BtnShowSalt.OnEvent("Click", ObjBindMethod(this, "OnToggleSalt"))
        this.Gui.Add("Button", "x+10 yp w110", "Edit").OnEvent("Click", ObjBindMethod(this, "OnChangeSalt"))

        ; List View
        this.Gui.Add("Text", "xm y+20", "Managed Keys:")
        this.LV := this.Gui.Add("ListView", "r12 w600 Grid vKeyList", ["Service", "Key Name", "Status", "Value"])
        this.LV.ModifyCol(1, 100) ; Service
        this.LV.ModifyCol(2, 150) ; Name
        this.LV.ModifyCol(3, 100) ; Status
        this.LV.ModifyCol(4, 230) ; Value
        this.LV.OnEvent("DoubleClick", ObjBindMethod(this, "OnEdit"))

        ; Action Buttons
        ; Unified Layout: [Reveal] [Edit] ... [Encrypt] [Decrypt]
        this.BtnReveal := this.Gui.Add("Button", "section w45", "👁")
        this.BtnReveal.OnEvent("Click", ObjBindMethod(this, "OnToggleReveal"))

        this.Gui.Add("Button", "ys w110", "Edit Selected").OnEvent("Click", ObjBindMethod(this, "OnEdit"))

        this.Gui.Add("Text", "ys w150", "") ; Spacer to push bulk actions right (adjust width as needed)

        this.Gui.Add("Button", "ys w110", "Encrypt All").OnEvent("Click", ObjBindMethod(this, "OnEncryptAll"))
        this.Gui.Add("Button", "ys w110", "Decrypt All").OnEvent("Click", ObjBindMethod(this, "OnDecryptAll"))

        ; Footer
        this.Gui.Add("Text", "xm y+15 w600 h1 0x10") ; Horizontal Line
        this.StatusBar := this.Gui.Add("Text", "xm y+5 w600", "Ready.")

        this.RefreshList()
        this.Gui.Show()
    }

    RefreshList() {
        this.LV.Delete()
        this.LV.Opt("-Redraw")

        for Item in this.ManagedKeys {
            Val := IniRead(CurrentSecretsPath, Item.Section, Item.Key, "")
            Status := "❌ Missing"
            DisplayVal := ""

            if (Val != "") {
                ; Check Encryption Status
                TempDecrypted := Security.Deobfuscate(Val, CurrentSalt)
                IsEncrypted := (SubStr(TempDecrypted, 1, 7) == "%%SEC%%")

                if (IsEncrypted) {
                    Status := "🔒 Encrypted"
                    RealVal := SubStr(TempDecrypted, 8)
                } else {
                    Status := "⚠️ Plain Text"
                    RealVal := Val
                }

                if (this.RevealMode)
                    DisplayVal := RealVal
                else
                    DisplayVal := "********************"
            }

            this.LV.Add(, Item.Section, Item.Name, Status, DisplayVal)
        }

        this.LV.Opt("+Redraw")
    }

    OnEdit(*) {
        Row := this.LV.GetNext()
        if (Row == 0) {
            MsgBox("Please select a key to edit.")
            return
        }

        Item := this.ManagedKeys[Row]

        ; Get current plain text value for editing
        CurrentPlain := ""
        Val := IniRead(CurrentSecretsPath, Item.Section, Item.Key, "")
        if (Val != "") {
            TempDecrypted := Security.Deobfuscate(Val, CurrentSalt)
            if (SubStr(TempDecrypted, 1, 7) == "%%SEC%%")
                CurrentPlain := SubStr(TempDecrypted, 8)
            else
                CurrentPlain := Val
        }

        ib := InputBox("Enter new value for " . Item.Name . ":", "Edit Key", "w400 h130", CurrentPlain)
        if (ib.Result == "OK") {
            NewVal := Trim(ib.Value)
            if (NewVal == "") {
                ; Maybe support deleting? For now just empty.
                IniDelete(CurrentSecretsPath, Item.Section, Item.Key)
            } else {
                ; Always encrypt on save from Edit
                Obfuscated := Security.Obfuscate("%%SEC%%" . NewVal, CurrentSalt)
                IniWrite(Obfuscated, CurrentSecretsPath, Item.Section, Item.Key)
            }
            this.RefreshList()
            this.StatusBar.Value := "Updated " . Item.Name
        }
    }

    OnToggleReveal(*) {
        this.RevealMode := !this.RevealMode
        this.BtnReveal.Text := this.RevealMode ? "🔒" : "👁"
        this.RefreshList()
    }

    OnEncryptAll(*) {
        Count := 0
        for Item in this.ManagedKeys {
            Val := IniRead(CurrentSecretsPath, Item.Section, Item.Key, "")
            if (Val == "")
                continue

            ; Check if plain
            TempDecrypted := Security.Deobfuscate(Val, CurrentSalt)
            IsEncrypted := (SubStr(TempDecrypted, 1, 7) == "%%SEC%%")

            if (!IsEncrypted) {
                ; Encrypt
                Obfuscated := Security.Obfuscate("%%SEC%%" . Val, CurrentSalt)
                IniWrite(Obfuscated, CurrentSecretsPath, Item.Section, Item.Key)
                Count++
            }
        }
        this.RefreshList()
        MsgBox("Encrypt All Complete. Secured " . Count . " keys.")
    }

    OnDecryptAll(*) {
        if (MsgBox("Are you sure you want to decrypt all keys to plain text?", "Confirm", 36) != "Yes")
            return

        Count := 0
        for Item in this.ManagedKeys {
            Val := IniRead(CurrentSecretsPath, Item.Section, Item.Key, "")
            if (Val == "")
                continue

            ; Check if encrypted
            TempDecrypted := Security.Deobfuscate(Val, CurrentSalt)
            IsEncrypted := (SubStr(TempDecrypted, 1, 7) == "%%SEC%%")

            if (IsEncrypted) {
                ; Decrypt
                Plain := SubStr(TempDecrypted, 8)
                IniWrite(Plain, CurrentSecretsPath, Item.Section, Item.Key)
                Count++
            }
        }
        this.RefreshList()
        MsgBox("Decrypt All Complete. Exposed " . Count . " keys.")
    }

    OnChangeSalt(*) {
        global CurrentSalt

        ; Warning / Confirmation
        MsgString := "WARNING: Changing the Salt involves re-encryption of all keys.`n"
        MsgString .= "The script will attempt to decrypt everything with the OLD salt first.`n"
        MsgString .= "If successful, it will save them with the NEW salt.`n`n"
        MsgString .= "Do you want to proceed?"

        if (MsgBox(MsgString, "Change Salt", 36 + 48) != "Yes")
            return

        ib := InputBox("Enter New Salt (Leave empty to auto-generate):", "New Salt", "w400 h130", "")
        if (ib.Result != "OK")
            return

        NewSalt := Trim(ib.Value)
        if (NewSalt == "")
            NewSalt := RandomString(16)

        ; 1. Load all current keys into memory (Decrypted)
        MemoryKeys := Map()

        for Item in this.ManagedKeys {
            Val := IniRead(CurrentSecretsPath, Item.Section, Item.Key, "")
            if (Val == "")
                continue

            ; Deobfuscate using OLD CurrentSalt
            TempDecrypted := Security.Deobfuscate(Val, CurrentSalt)
            IsEncrypted := (SubStr(TempDecrypted, 1, 7) == "%%SEC%%")

            if (IsEncrypted) {
                MemoryKeys[Item.Section . "|" . Item.Key] := SubStr(TempDecrypted, 8)
            } else {
                ; Keep plain text as is (will be encrypted with new salt if loop logic dictates)
                MemoryKeys[Item.Section . "|" . Item.Key] := Val
            }
        }

        ; 2. Commit New Salt
        CurrentSalt := NewSalt
        IniWrite(CurrentSalt, SettingsPath, "Security", "Salt")
        this.Gui["SaltDisplay"].Value := CurrentSalt

        ; 3. Re-Write Keys with New Salt
        Count := 0
        for Item in this.ManagedKeys {
            MapKey := Item.Section . "|" . Item.Key
            if (MemoryKeys.Has(MapKey)) {
                PlainVal := MemoryKeys[MapKey]
                ; Always encrypt when saving new salt
                Obfuscated := Security.Obfuscate("%%SEC%%" . PlainVal, CurrentSalt)
                IniWrite(Obfuscated, CurrentSecretsPath, Item.Section, Item.Key)
                Count++
            }
        }

        this.RefreshList()
        MsgBox("Salt updated successfully!`nRe-processed " . Count . " keys.")
    }

    OnToggleSalt(*) {
        this.SaltVisible := !this.SaltVisible
        if (this.SaltVisible) {
            this.SaltEdit.Opt("-Password")
            this.BtnShowSalt.Text := "🔒"
        } else {
            this.SaltEdit.Opt("+Password")
            this.BtnShowSalt.Text := "👁"
        }
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
