; --- Глобальные переменные ---
isShortPress := true ; Флаг для определения типа нажатия

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

; Функция, выполняющая саму прокрутку
ScrollDownTimer() {
    ScrollDownCount := GetScrollCount()
    loop ScrollDownCount {
        Send("{WheelDown}")
        Sleep(50)
    }
}

; Эта функция сработает через 500 мс после нажатия
LongPressAction() {
    isShortPress := false      ; Опускаем флаг, теперь нажатие считается долгим
    SetTimer(ScrollDownTimer, 50) ; Включаем непрерывную прокрутку
}

; --- Основные горячие клавиши ---

; Срабатывает при НАЖАТИИ физической клавиши sc028
^!sc028::
{
    isShortPress := true ; Взводим флаг при каждом новом нажатии
    SetTimer(LongPressAction, -500) ; Запускаем одноразовый таймер на 500 мс
}

; Срабатывает при ОТПУСКАНИИ физической клавиши sc028
^!sc028 up::
{
    ; Немедленно отключаем все таймеры
    SetTimer(LongPressAction, 0)  ; Отключаем таймер долгого нажатия
    SetTimer(ScrollDownTimer, 0) ; Отключаем прокрутку (если она была запущена)

    ; Если флаг не успел опуститься, значит, это было короткое нажатие
    if isShortPress
    {
        Click()
    }
}