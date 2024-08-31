; JoyToKey settings: Ctrl, C-> Ctrl, Shift, Alt, L-> Ctrl, V -> None

#Persistent

^!U::
    ; Шаг 1: Копируем выделенный фрагмент текста в буфер обмена
    Send, ^c
    ClipWait, 1 ; Ожидаем, пока данные будут скопированы

    ; Шаг 2: Запускаем утилиту uppercase_util_v1 в тихом режиме
    RunWait, C:\Tools\uppercase_util\dist\uppercase_util_v1.exe,, Hide
    Sleep, 1000 ; Можно изменить задержку по вашему желанию

    ; Шаг 3: Вставляем содержимое буфера обмена
    Send, ^v

    ; Шаг 4: Ждем некоторое время, чтобы утилита обработала вставленные данные
    ;Sleep, 1000 ; Можно изменить задержку по вашему желанию
    
return