; В v2 #Persistent не нужен, если есть горячие клавиши
; Глобальная переменная для хранения времени нажатия. 
; В v2 переменные, объявленные в самом начале, глобальны по умолчанию.
KeyDownTime := 0

; --- Функции ---

; Функция для определения количества строк для прокрутки
GetScrollCount() {
    if WinActive("ahk_exe app.exe") {
        return 1
    }
    else if WinActive("ahk_exe chrome.exe") {
        return 3
    }
    else {
        return 1
    }
}

; Функция, которая запускает непрерывную прокрутку
StartScroll() {
    ; Передаем объект функции напрямую - это стандарт v2
    SetTimer(ScrollDownTimer, 50) 
}

; Функция, выполняющая саму прокрутку
ScrollDownTimer() {
    ScrollDownCount := GetScrollCount()
    ; В v2 скобки вокруг переменной в loop не обязательны
    loop ScrollDownCount {
        Send("{WheelDown}")
        Sleep(50)
    }
}


; --- Горячие клавиши ---

; Срабатывает при НАЖАТИИ Ctrl + Alt + '
^!'::
{
    ; Запоминаем точное время нажатия
    KeyDownTime := A_TickCount
    ; Устанавливаем таймер, который сработает ОДИН РАЗ через 500 мс и запустит прокрутку
    SetTimer(StartScroll, -500)
}

; Срабатывает при ОТПУСКАНИИ Ctrl + Alt + '
^!' up::
{
    ; Отключаем таймер, который должен был запустить прокрутку
    SetTimer(StartScroll, "Off")
    ; Также останавливаем саму прокрутку, если она уже была запущена
    SetTimer(ScrollDownTimer, "Off")

    ; Вычисляем, как долго была зажата клавиша
    PressDuration := A_TickCount - KeyDownTime

    ; Если клавиша была зажата менее 500 мс, выполняем клик
    if (PressDuration < 500)
    {
        ; ВАЖНО: Как мы выяснили ранее, простая команда Click()
        ; работает надежнее, чем Send(). Если Send() не сработает,
        ; замените строку ниже на просто Click()
        Click()
    }
}