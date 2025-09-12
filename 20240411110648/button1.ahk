; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Задержка в миллисекундах, после которой скрипт проверит, нужно ли включать прокрутку.
scrollDelay := 250 

; "Мертвая зона" в пикселях. Если курсор сдвинулся меньше этого значения по X или Y,
; будет включена прокрутка. Поэкспериментируйте со значением от 10 до 30.
dragThreshold := 15 


; ====================================================================================
; --- Script Logic ---
; ====================================================================================
global isScrolling := false
global startX := 0, startY := 0

GetScrollCount() {
    if WinActive("ahk_exe chrome.exe") {
        return 3
    }
    return 1
}

ScrollDownTimer() {
    loop GetScrollCount() {
        Send("{WheelDown}")
        Sleep(50)
    }
}

; Функция, которая проверяет, нужно ли начинать прокрутку.
CheckForScroll() {
    global isScrolling, startX, startY, dragThreshold
    
    MouseGetPos(&endX, &endY)
    
    ; Проверяем, что курсор почти не сдвинулся с начальной точки.
    if (Abs(startX - endX) < dragThreshold) && (Abs(startY - endY) < dragThreshold)
    {
        isScrolling := true
        Send("{LButton Up}") ; Отменяем зажатие, чтобы начать скролл.
        SetTimer(ScrollDownTimer, 50)
    }
}

; --- Hotkeys ---

; "$" нужен, чтобы хоткей не запускал сам себя через команду Send.
$^!sc028::
{
    global isScrolling, startX, startY, scrollDelay
    
    isScrolling := false
    MouseGetPos(&startX, &startY) ; Запоминаем начальную позицию.
    
    Send("{LButton Down}") ; Немедленно зажимаем ЛКМ для выделения.
    SetTimer(CheckForScroll, -scrollDelay) ; Запускаем одноразовую проверку на скролл.
}

$^!sc028 up::
{
    global isScrolling
    
    ; Отключаем таймер проверки на случай, если кнопка была отпущена очень быстро.
    SetTimer(CheckForScroll, 0) 
    
    if isScrolling
    {
        SetTimer(ScrollDownTimer, 0) ; Если скроллили, останавливаем скролл.
    }
    else
    {
        Send("{LButton Up}") ; Если выделяли, отпускаем ЛКМ.
    }
}