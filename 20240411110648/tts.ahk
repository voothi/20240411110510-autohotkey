; #Persistent  ; Ensures the script stays in memory

; Функция, которая копирует текст и запускает Python-скрипт с указанным языком
RunPythonScript(lang) {
    ; Шаг 1: Копируем выделенный фрагмент текста в буфер обмена
    Send("^c")
    ClipWait(1) ; цитата

    ; Шаг 2: Запускаем скрипт Python в тихом режиме
    RunWait("C:\Python\Python312\python.exe C:\Tools\piper-tts\piper_tts.py --lang " lang " --clipboard", "", "Hide")
    Sleep(1000) ; Можно изменить задержку по вашему желанию
}

^!2::RunPythonScript("en")
^!3::RunPythonScript("de")
^!4::RunPythonScript("ru")