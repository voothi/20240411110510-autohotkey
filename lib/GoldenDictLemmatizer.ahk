#Requires AutoHotkey v2.0

; ===================================================================================
; Library:      GoldenDict Lemmatizer integration helper
;
; Description:  Implements in-process word lemmatization utilizing kardenwort-lite.
;               Designed to be dynamically included via `#Include "*i Lib\gd-lemmatizer.ahk"`.
;               Works silently and handles dynamic tray icon language display.
; ===================================================================================

; --- Global State Variables ---
global lemCurrentLang := "AU"
global lemLangCodes := ["AU", "EN", "DE", "RU", "UK"]
global lemLangInfo := Map()
global lemHIcon := 0

lemLangInfo["AU"] := { text: "AU", bg: 0x4B0082, fg: 0xFFFFFF, langs: "en,de,ru,uk" } ; Indigo
lemLangInfo["EN"] := { text: "EN", bg: 0x008000, fg: 0xFFFFFF, langs: "en" }       ; Green
lemLangInfo["DE"] := { text: "DE", bg: 0x8B0000, fg: 0xFFFFFF, langs: "de" }       ; Dark Red
lemLangInfo["RU"] := { text: "RU", bg: 0x00008B, fg: 0xFFFFFF, langs: "ru" }       ; Dark Blue
lemLangInfo["UK"] := { text: "UK", bg: 0xFFD700, fg: 0x000000, langs: "uk" }       ; Yellow/Black

; Initialize AHK Integration automatically if included
UpdateLemTrayMenu()

UpdateLemTrayMenu() {
    global lemCurrentLang, lemLangInfo, lemLangCodes
    
    lemMenu := Menu()
    for code in lemLangCodes {
        info := lemLangInfo[code]
        lemMenu.Add(info.text " (" code ")", ((c, *) => SetLemLanguage(c)).Bind(code))
    }
    
    try {
        A_TrayMenu.Add("Lemmatizer Language", lemMenu)
    }
    
    UpdateLemTrayIcon()
}

SetLemLanguage(lang) {
    global lemCurrentLang := lang
    UpdateLemTrayIcon()
}

UpdateLemTrayIcon() {
    global lemCurrentLang, lemLangInfo, lemHIcon
    
    info := lemLangInfo.Has(lemCurrentLang) ? lemLangInfo[lemCurrentLang] : { text: "??", bg: 0x808080, fg: 0xFFFFFF }
    newIcon := LemCreateIconFromText(info.text, info.bg, info.fg)
    if (newIcon) {
        TraySetIcon("HICON:" . newIcon)
        if (lemHIcon)
            DllCall("DestroyIcon", "Ptr", lemHIcon)
        lemHIcon := newIcon
    }
}

LemCreateIconFromText(text, bgColor, textColor) {
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

LemmatizeWord(word) {
    global lemCurrentLang, lemLangInfo
    
    ; Only lemmatize if the word contains no spaces and is not empty
    if (word != "" && !RegExMatch(word, "\s"))
    {
        pythonScript := "U:\voothi\20241223170748-kardenwort\src\kardenwort\core\kardenwort_lite.py"
        
        if FileExist(pythonScript) {
            ; Build language argument
            langArg := ""
            if (lemLangInfo.Has(lemCurrentLang)) {
                langArg := ' --langs="' . lemLangInfo[lemCurrentLang].langs . '"'
            }
            
            ; Escape double quotes in the word to prevent command line injection
            safeWord := StrReplace(word, '"', '\"')
            
            ; Set clipboard, run python silently, and wait
            A_Clipboard := word
            try {
                RunWait('python "' . pythonScript . '" "' . safeWord . '"' . langArg, , "Hide")
                return A_Clipboard
            } catch {
                ; Fallback if python fails to run (e.g. not in PATH)
                return word
            }
        }
    }
    return word
}

