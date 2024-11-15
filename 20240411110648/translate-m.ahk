; 20241114182044
#Persistent

; Переменные для отслеживания состояния
isSelectionMode := false  ; Режим выделения включен или нет
; Переменная, чтобы отслеживать состояние средней кнопки
isMiddleButtonPressed := false

; Комбинация клавиш для включения/выключения режима
^!e::  ; Ctrl + Alt + E
    isSelectionMode := !isSelectionMode  ; Переключаем режим выделения
    if (isSelectionMode) {
        ToolTip, Mode: on ; Показываем уведомление
        Sleep, 1000  ; Задержка для показа уведомления
        ToolTip  ; Убираем уведомление
    } else {
        ToolTip, Mode: off ; Показываем уведомление
        Sleep, 1000  ; Задержка для показа уведомления
        ToolTip  ; Убираем уведомление
    }
return

~MButton::
    if (isSelectionMode) {
        ; if (WinActive("ahk_class Chrome_WidgetWin_1")) {

        ; }
        
        if !isMiddleButtonPressed {
            isMiddleButtonPressed := true  ; Устанавливаем статус нажатия
            Send ^c  ; Эмулируем нажатие Ctrl+C
            Sleep 250  ; Задержка для предотвращения избыточного использования ресурсов
        }

        ; Эмулируем нажатие средней кнопки мыши, пока она зажата
        while isMiddleButtonPressed {
            Send ^c  ; Эмулируем нажатие Ctrl+C
            Sleep 250  ; Задержка для предотвращения избыточного использования ресурсов
            Send {MButton down}  ; Эмулируем нажатие средней кнопки
        }

        ; Отпускаем среднюю кнопку, когда она отпущена
        Send {MButton up}
    }
return

; Обработчик отпускания средней кнопки мыши
~MButton Up::
    if (isSelectionMode) {
        ; Здесь можно добавить дополнительные действия при отпускании кнопки
        isMiddleButtonPressed := false  ; Сбрасываем статус нажатия
    }
return