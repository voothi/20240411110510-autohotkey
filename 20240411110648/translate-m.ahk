; #Persistent

; ; Переменные для отслеживания нажатий
; doubleClickTime := 500   ; Время для двойного клика в миллисекундах
; lastClickTime := 0       ; Время последнего нажатия
; clickCount := 0          ; Счетчик нажатий

; ; Обработчик нажатия средней кнопки мыши
; ~MButton::
;     currentTime := A_TickCount  ; Получаем текущее время

;     if (currentTime - lastClickTime <= doubleClickTime) {
;         clickCount++  ; Увеличиваем счетчик нажатий
;     } else {
;         clickCount := 1  ; Сбрасываем счетчик, если прошло больше времени
;     }

;     lastClickTime := currentTime  ; Обновляем время последнего нажатия

;     ; Проверяем, было ли нажатие один раз
;     if (clickCount = 1) {
;         ; Эмулируем нажатие Ctrl+C
;         Send ^c
;     }

;     ; Проверяем, было ли нажатие дважды
;     if (clickCount = 2) {
;         ; Эмулируем нажатие Ctrl+C еще раз
;         Send ^c
;         clickCount := 0  ; Сбрасываем счетчик после выполнения
;     }
; return

; 20241114181100
; #Persistent

; ; Переменная, чтобы отслеживать состояние средней кнопки
; isMiddleButtonPressed := false

; ; Обработчик нажатия средней кнопки мыши
; ~MButton::
;     Send ^c  ; Эмулируем нажатие Ctrl+C
;     if !isMiddleButtonPressed {
;         isMiddleButtonPressed := true  ; Устанавливаем статус нажатия
;     }
;     KeyWait, MButton  ; Ждем, пока кнопка не будет отпущена
;     isMiddleButtonPressed := false  ; Сбрасываем статус нажатия
; return

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

; 20241114182709
; ~MButton::
;     Send ^c  ; Эмулируем нажатие Ctrl+C
; return
