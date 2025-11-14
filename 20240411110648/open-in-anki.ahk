#Requires AutoHotkey v2.0

; --- Пути к вашим файлам ---
pythonPath := "C:\Python\Python312\python.exe"
scriptPath := "C:\Tools\anki-search\anki-search.py"

; --- Горячая клавиша, активная только в окне GoldenDict ---
#HotIf WinActive("ahk_exe goldendict.exe")

^!a::
{
    ; Этот синтаксис абсолютно правильный для v2.
    ; Предупреждение появлялось из-за запуска через v1.
    ; local savedClipboard
    ; savedClipboard := ClipboardAll

    ; Копируем выделенный текст
    A_Clipboard := ""
    SendInput("^c")
    
    if !ClipWait(1)
        Return

    ; Формируем команду и запускаем ее в скрытом режиме
    local command := '"' . pythonPath . '" "' . scriptPath . '" --browse-clipboard'
    Run(command,, "Hide")

    ; Возвращаем старое содержимое буфера обмена
    ; Sleep(300)
    ; A_Clipboard := savedClipboard
}

#HotIf