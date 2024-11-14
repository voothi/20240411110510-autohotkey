; 20241114182044
#Persistent

; Переменная, чтобы отслеживать состояние средней кнопки
isMiddleButtonPressed := false

; Обработчик нажатия средней кнопки мыши
~MButton::
    if !isMiddleButtonPressed {
        isMiddleButtonPressed := true  ; Устанавливаем статус нажатия
    }
    
    ; Эмулируем нажатие средней кнопки мыши, пока она зажата
    while isMiddleButtonPressed {
        Send ^c  ; Эмулируем нажатие Ctrl+C
        Send {MButton down}  ; Эмулируем нажатие средней кнопки
        Sleep 250  ; Задержка для предотвращения избыточного использования ресурсов
    }

    ; Отпускаем среднюю кнопку, когда она отпущена
    Send {MButton up}
return

; Обработчик отпускания средней кнопки мыши
~MButton Up::
    isMiddleButtonPressed := false  ; Сбрасываем статус нажатия
return