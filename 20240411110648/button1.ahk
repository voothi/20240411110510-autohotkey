; #Persistent

; Глобальная переменная для хранения времени нажатия клавиши
global KeyDownTime := 0

; --- Функции ---

; Функция для определения количества строк для прокрутки в зависимости от активного окна
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

; Функция, которая запускает непрерывную прокрутку (срабатывает по таймеру)
StartScroll() {
    SetTimer(ScrollDownTimer, 50) ; Включаем повторяющийся таймер для прокрутки
}

; Функция, выполняющая саму прокрутку
ScrollDownTimer() {
    ScrollDownCount := GetScrollCount()
    loop (ScrollDownCount) {
        Send("{WheelDown}")
        Sleep(50)
    }
}

; --- Горячие клавиши ---

; Срабатывает при НАЖАТИИ Ctrl + Alt + '
^!':: {
    ; Запоминаем точное время нажатия
    KeyDownTime := A_TickCount
    ; Устанавливаем таймер, который сработает ОДИН РАЗ через 500 мс и запустит прокрутку
    SetTimer(StartScroll, -500)
    return
}

; Срабатывает при ОТПУСКАНИИ Ctrl + Alt + '
^!' up:: {
    ; Отключаем таймер, который должен был запустить прокрутку.
    SetTimer(StartScroll, 0)
    ; Также останавливаем саму прокрутку, если она уже была запущена
    SetTimer(ScrollDownTimer, 0)

    ; Вычисляем, как долго была зажата клавиша
    PressDuration := A_TickCount - KeyDownTime

    ; Если клавиша была зажата менее 500 мс, выполняем клик левой кнопкой мыши
    if (PressDuration < 500) {
        ; ИЗМЕНЕНИЕ: Используем SendInput для более надежной эмуляции клика
        KeyWait("Control")
        KeyWait("Alt")
        ; Делаем небольшую паузу на всякий случай
        Sleep(20) 
        SendInput("{LButton}")
    }
    return
}