; JoyToKey settings: Ctrl, C-> Ctrl, Shift, Alt, L-> Ctrl, V -> None

#Persistent

^+!S::
    ; Нажимаем левую кнопку мыши
    Click

    ; Нажимаем Home
    Send, {Home}
    Sleep, 200 ; Пауза 200 мс

    ; Нажимаем Ctrl+A
    Send, ^a
    Sleep, 200 ; Пауза 200 мс

    ; Нажимаем Ctrl+C
    Send, ^c
    Sleep, 200 ; Пауза 200 мс

    ; Нажимаем Ctrl+S
    Send, ^s
    Sleep, 200 ; Пауза 200 мс

    ; Нажимаем Space
    Send, {Space}
    ; Нажимаем Backspace
    Send, {Backspace}
    Sleep, 1000 ; Пауза 200 мс

    ; Вставляем в окно
    Send, ^v
return