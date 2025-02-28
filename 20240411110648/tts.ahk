; #Persistent  ; Обеспечивает, что скрипт остается в памяти

^!1:: {
    ; Шаг 1: Копируем выделенный фрагмент текста в буфер обмена
    Send("^c")
    ClipWait(1) ; Ожидаем, пока данные будут скопированы

    ; Шаг 2: Запускаем скрипт Python в тихом режиме
    RunWait("C:\Python\Python312\python.exe C:\Tools\piper-tts\piper_tts.py --lang en --clipboard", "", "Hide")
    Sleep(1000) ; Можно изменить задержку по вашему желанию
}


^!2:: {
    ; Шаг 1: Копируем выделенный фрагмент текста в буфер обмена
    Send("^c")
    ClipWait(1) ; Ожидаем, пока данные будут скопированы

    ; Шаг 2: Запускаем скрипт Python в тихом режиме
    RunWait("C:\Python\Python312\python.exe C:\Tools\piper-tts\piper_tts.py --lang de --clipboard", "", "Hide")
    Sleep(1000) ; Можно изменить задержку по вашему желанию
}

^!3:: {
    ; Шаг 1: Копируем выделенный фрагмент текста в буфер обмена
    Send("^c")
    ClipWait(1) ; Ожидаем, пока данные будут скопированы

    ; Шаг 2: Запускаем скрипт Python в тихом режиме
    RunWait("C:\Python\Python312\python.exe C:\Tools\piper-tts\piper_tts.py --lang ru --clipboard", "", "Hide")
    Sleep(1000) ; Можно изменить задержку по вашему желанию
}
