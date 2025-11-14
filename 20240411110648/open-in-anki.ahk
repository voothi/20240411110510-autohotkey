#Requires AutoHotkey v2.0

; --- Пути к вашим файлам ---
pythonPath := "C:\Python\Python312\python.exe"
scriptPath := "C:\Tools\anki-search\anki-search.py"

; --- Горячая клавиша (работает везде) ---
^!a::
{
    ; 1. Очищаем буфер, копируем выделенный текст
    A_Clipboard := ""
    SendInput("^c")
    
    ; 2. Ждём копирования, если не вышло - выходим
    if !ClipWait(1)
        Return

    ; 3. Формируем и запускаем команду. Окно консоли появится.
    local command := '"' . pythonPath . '" "' . scriptPath . '" --browse-clipboard'
    Run(command)
}