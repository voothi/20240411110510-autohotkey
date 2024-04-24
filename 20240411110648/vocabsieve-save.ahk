; JoyToKey settings: Ctrl, C-> Ctrl, Shift, Alt, L-> Ctrl, V -> None

#Persistent

^+!S::
    ; Нажимаем Ctrl+A
    Send, ^a
    ;Sleep, 200 ; Пауза 200 мс

    ; Нажимаем Ctrl+C
    Send, ^c
    ;Sleep, 200 ; Пауза 200 мс

    ; Нажимаем Ctrl+S
    Send, ^s
    Sleep, 200 ; Пауза 200 мс

    ; Нажимаем Space
    Send, {Space}
    Sleep, 1000 ; Пауза 200 мс

    ; Вставляем в окно
    Send, ^v
return