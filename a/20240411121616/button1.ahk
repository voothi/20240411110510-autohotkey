^+':: ; Привязываем к комбинации клавиш Ctrl + Shift + Alt + Quote
    global ScrollDownTimer
    ScrollDownCount := 3 ; Количество строк, на которое вы хотите прокрутить вниз (измените по своему усмотрению)
    Loop, %ScrollDownCount%
    {
        Send {WheelDown} ; Эмулируем действие прокрутки колеса мыши вниз
        Sleep 50 ; Подождите немного между каждым действием прокрутки
    }
    ScrollDownTimer := A_TickCount
    SetTimer, ScrollDown, 50
return

ScrollDown:
    if (GetKeyState("Ctrl", "P") && GetKeyState("Shift", "P") && GetKeyState("Alt", "P") && GetKeyState("'", "P")) ; Проверяем, удерживаются ли все четыре клавиши
    {
        if (A_TickCount - ScrollDownTimer >= 1000) ; Если клавиши удерживаются более 1 секунды
        {
            Send {WheelDown} ; Продолжаем прокрутку колеса мыши вниз
        }
    }
    else
    {
        SetTimer, ScrollDown, Off ; Если комбинация клавиш не удерживается, отключаем таймер
    }
return
