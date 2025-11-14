#Requires AutoHotkey v2.0

; --- Пути к вашим файлам ---
pythonPath := "C:\Python\Python312\python.exe"
scriptPath := "C:\Tools\anki-search\anki-search.py"

; --- Горячая клавиша, активная только в окне GoldenDict ---
#HotIf WinActive("ahk_exe goldendict.exe")

^!a::
{
    ; 1. Копируем выделенный текст
    A_Clipboard := ""
    SendInput("^c")
    
    if !ClipWait(1)
        Return

    ; 2. Формируем команду и запускаем Python-скрипт в скрытом режиме
    local command := '"' . pythonPath . '" "' . scriptPath . '" --browse-clipboard'
    Run(command,, "Hide")

    ; 3. ЖДЁМ ПОЯВЛЕНИЯ ОКНА БРАУЗЕРА ANKI И АКТИВИРУЕМ ЕГО
    ; WinWait будет ждать до 2 секунд, пока окно с заголовком "Browse" не появится.
    if WinWait("Browse ahk_exe anki.exe",, 2)
    {
        ; Если окно появилось, делаем его активным.
        WinActivate("Browse ahk_exe anki.exe")
    }
}

#HotIf