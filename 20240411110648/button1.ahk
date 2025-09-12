; ====================================================================================
; --- User Configuration ---
; ====================================================================================

; Задержка в миллисекундах, после которой начнется прокрутка, если курсор не двигался.
scrollDelay := 200 

; Порог движения курсора в пикселях. Если курсор сдвинулся больше, прокрутка не начнется.
dragThreshold := 10 


; ====================================================================================
; --- Script Logic ---
; ====================================================================================
isScrolling := false

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

; Функция, которая запускает прокрутку, если мышь не двигалась
CheckForScroll() {
    MouseGetPos(&startX, &startY)
    Sleep(scrollDelay)
    
    ; Если кнопка все еще зажата
    if GetKeyState("sc028", "P")
    {
        MouseGetPos(&endX, &endY)
        ; И если курсор почти не сдвинулся
        if (Abs(startX - endX) < dragThreshold) && (Abs(startY - endY) < dragThreshold)
        {
            isScrolling := true
            Send("{LButton Up}") ; Отменяем зажатие, чтобы начать скролл
            SetTimer(ScrollDownTimer, 50)
        }
    }
}

; --- Горячие клавиши ---

; Используем "$" чтобы хоткей не запускал сам себя
$^!sc028::
{
    isScrolling := false
    Send("{LButton Down}") ; Немедленно зажимаем ЛКМ для выделения
    SetTimer(CheckForScroll, -1) ; Запускаем проверку на скролл
}

$^!sc028 up::
{
    if isScrolling
    {
        SetTimer(ScrollDownTimer, 0) ; Если скроллили, останавливаем скролл
    }
    else
    {
        Send("{LButton Up}") ; Если выделяли, отпускаем ЛКМ
    }
    SetTimer(CheckForScroll, 0)
}