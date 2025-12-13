#Requires AutoHotkey v2.0
#Include ..\Lib\Security.ahk

; ==============================================================================
; Security Manager GUI
; ==============================================================================
; A centralized interface for managing secure API keys.
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

    __New() {
        this.Gui := Gui("+Resize +MinSize600x400", "Security Manager")
        this.Gui.SetFont("s10", "Segoe UI")
        this.Gui.OnEvent("Close", (*) => ExitApp())

        ; Header
        this.Gui.SetFont("Bold")
        this.Gui.Add("Text", "w600", "Secure Storage Location:")
        this.Gui.SetFont("Norm")
        this.Gui.Add("Edit", "w600 ReadOnly vSecretsPath", CurrentSecretsPath)

        ; List View
        this.Gui.Add("Text", "xm y+10", "Managed Keys:")
        this.LV := this.Gui.Add("ListView", "r12 w600 Grid vKeyList", ["Service", "Key Name", "Status", "Value"])
        this.LV.ModifyCol(1, 100) ; Service
        this.LV.ModifyCol(2, 150) ; Name
        this.LV.ModifyCol(3, 100) ; Status
        this.LV.ModifyCol(4, 230) ; Value
        this.LV.OnEvent("DoubleClick", ObjBindMethod(this, "OnEdit"))

        ; Action Buttons
        this.Gui.Add("Button", "w110 Section", "Edit Selected").OnEvent("Click", ObjBindMethod(this, "OnEdit"))
        this.BtnReveal := this.Gui.Add("Button", "ys w110", "Reveal Values")
        this.BtnReveal.OnEvent("Click", ObjBindMethod(this, "OnToggleReveal"))

        this.Gui.Add("Text", "ys+5 w20", "") ; Spacer

        this.Gui.Add("Button", "ys w110", "Encrypt All").OnEvent("Click", ObjBindMethod(this, "OnEncryptAll"))
        this.Gui.Add("Button", "ys w110", "Decrypt All").OnEvent("Click", ObjBindMethod(this, "OnDecryptAll"))

        ; Footer
        this.Gui.Add("StatusBar", , "Ready.")

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
            this.Gui["StatusBar"].SetText("Updated " . Item.Name)
        }
    }

    OnToggleReveal(*) {
        this.RevealMode := !this.RevealMode
        this.BtnReveal.Text := this.RevealMode ? "Hide Values" : "Reveal Values"
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
