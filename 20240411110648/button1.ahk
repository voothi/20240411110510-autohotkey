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

; --- Основная горячая клавиша ---
; Используем ОДИН обработчик с KeyWait для максимальной надежности.
; sc028 - это физическая клавиша, не зависящая от раскладки.
^!sc028::
{
    ; Ждем отпускания физической клавиши sc028 с таймаутом 0.5 секунды.
    ; KeyWait возвращает 1, если время вышло, и 0, если клавишу отпустили.
    timedOut := KeyWait("sc028", "T0.5")

    ; Если время НЕ вышло (timedOut = 0), значит это было короткое нажатие.
    if !timedOut
    {
        Click()
        return
    }
    ; Если мы здесь, значит время вышло (timedOut = 1) - это долгое удержание.
    else
    {
        ; Запускаем непрерывную прокрутку.
        SetTimer(ScrollDownTimer, 50)

        ; Теперь ждем, пока клавиша будет наконец отпущена (уже без таймаута).
        KeyWait("sc028")

        ; Как только клавишу отпустили, останавливаем прокрутку.
        SetTimer(ScrollDownTimer, 0)
        return
    }
}