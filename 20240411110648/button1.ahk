; Глобальная переменная для хранения времени нажатия
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
    SetTimer(ScrollDownTimer, 50) 
}

; Функция, выполняющая саму прокрутку
ScrollDownTimer() {
    ScrollDownCount := GetScrollCount()
    loop ScrollDownCount {
        Send("{WheelDown}")
        Sleep(50)
    }
}


; --- Горячие клавиши ---
; ИСПОЛЬЗУЕМ СКАН-КОД КЛАВИШИ (sc028), чтобы хоткей не зависел от раскладки.
; sc028 - это стандартный код для клавиши ' / " (где 'э' в русской раскладке).

; Срабатывает при НАЖАТИИ физической клавиши
^!sc028::
{
    KeyDownTime := A_TickCount
    SetTimer(StartScroll, -500)
}

; Срабатывает при ОТПУСКАНИИ физической клавиши
^!sc028 up::
{
    ; Отключаем таймеры с помощью 0
    SetTimer(StartScroll, 0)
    SetTimer(ScrollDownTimer, 0)

    PressDuration := A_TickCount - KeyDownTime

    if (PressDuration < 500)
    {
        Click()
    }
}