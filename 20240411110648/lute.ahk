^!+F1:: {
    ; Проверяем, активен ли Chrome
    if WinActive("ahk_exe chrome.exe") {
        ; Получаем заголовок активного окна
        title := WinGetTitle("A")

        ; Проверяем, содержит ли заголовок слово "Reading"
        if InStr(title, "Reading", false) || InStr(title, "Translate", false) {
            ; Шаг 1: Задержка перед отправкой комбинации клавиш (например, 500 миллисекунд)
            Sleep(500)

            ; Шаг 4: Получаем текущую позицию мыши
            MouseGetPos(&xpos, &ypos)

            ; Шаг 5: Двигаем указатель мыши на 1024 пикселя вправо
            MouseMove(xpos + 1024, ypos, 0)

            ; Шаг 6: Возвращаем указатель в исходное положение
            MouseMove(xpos, ypos, 0)
            Sleep(500)

            ; Кликаем по координатам (15, 200)
            ; Click 15, 540
            ; Sleep(100)

            Click 1200, 540
            ; Sleep(100)

            Send("+!s")
            Sleep(500)

            ; Отправляем клавишу "1"
            Send("1")
        }
    }
}

^!+F2:: {
    ; Проверяем, активен ли Chrome
    if WinActive("ahk_exe chrome.exe") || InStr(title, "Translate", false) {
        ; Получаем заголовок активного окна
        title := WinGetTitle("A")

        ; Проверяем, содержит ли заголовок слово "Reading"
        if InStr(title, "Reading", false) {
            ; Шаг 1: Задержка перед отправкой комбинации клавиш (например, 500 миллисекунд)
            Sleep(500)

            ; Шаг 4: Получаем текущую позицию мыши
            MouseGetPos(&xpos, &ypos)

            ; Шаг 5: Двигаем указатель мыши на 1024 пикселя вправо
            MouseMove(xpos + 1024, ypos, 0)

            ; Шаг 6: Возвращаем указатель в исходное положение
            MouseMove(xpos, ypos, 0)
            Sleep(500)

            ; Кликаем по координатам (15, 200)
            ; Click 15, 540
            ; Sleep(100)

            Click 1200, 540
            ; Sleep(100)

            Send("+!s")
            Sleep(500)

            Send("2")
        }
    }
}

^!+F3:: {
    ; Проверяем, активен ли Chrome
    if WinActive("ahk_exe chrome.exe") || InStr(title, "Translate", false) {
        ; Получаем заголовок активного окна
        title := WinGetTitle("A")

        ; Проверяем, содержит ли заголовок слово "Reading"
        if InStr(title, "Reading", false) {
            ; Шаг 1: Задержка перед отправкой комбинации клавиш (например, 500 миллисекунд)
            Sleep(500)

            ; Шаг 4: Получаем текущую позицию мыши
            MouseGetPos(&xpos, &ypos)

            ; Шаг 5: Двигаем указатель мыши на 1024 пикселя вправо
            MouseMove(xpos + 1024, ypos, 0)

            ; Шаг 6: Возвращаем указатель в исходное положение
            MouseMove(xpos, ypos, 0)
            Sleep(500)

            ; Кликаем по координатам (15, 200)
            ; Click 15, 540
            ; Sleep(100)

            Click 1200, 540
            ; Sleep(100)

            Send("+!s")
            Sleep(500)

            Send("3")
        }
    }
}

^!+F4:: {
    ; Проверяем, активен ли Chrome
    if WinActive("ahk_exe chrome.exe") || InStr(title, "Translate", false) {
        ; Получаем заголовок активного окна
        title := WinGetTitle("A")

        ; Проверяем, содержит ли заголовок слово "Reading"
        if InStr(title, "Reading", false) {
            ; Шаг 1: Задержка перед отправкой комбинации клавиш (например, 500 миллисекунд)
            Sleep(500)

            ; Шаг 4: Получаем текущую позицию мыши
            MouseGetPos(&xpos, &ypos)

            ; Шаг 5: Двигаем указатель мыши на 1024 пикселя вправо
            MouseMove(xpos + 1024, ypos, 0)

            ; Шаг 6: Возвращаем указатель в исходное положение
            MouseMove(xpos, ypos, 0)
            Sleep(500)

            ; Кликаем по координатам (15, 200)
            ; Click 15, 540
            ; Sleep(100)

            Click 1200, 540
            ; Sleep(100)

            Send("+!s")
            Sleep(500)

            Send("4")
        }
    }
}

^!+F5:: {
    ; Проверяем, активен ли Chrome
    if WinActive("ahk_exe chrome.exe") || InStr(title, "Translate", false) {
        ; Получаем заголовок активного окна
        title := WinGetTitle("A")

        ; Проверяем, содержит ли заголовок слово "Reading"
        if InStr(title, "Reading", false) {
            ; Шаг 1: Задержка перед отправкой комбинации клавиш (например, 500 миллисекунд)
            Sleep(500)

            ; Шаг 4: Получаем текущую позицию мыши
            MouseGetPos(&xpos, &ypos)

            ; Шаг 5: Двигаем указатель мыши на 1024 пикселя вправо
            MouseMove(xpos + 1024, ypos, 0)

            ; Шаг 6: Возвращаем указатель в исходное положение
            MouseMove(xpos, ypos, 0)
            Sleep(500)

            ; Кликаем по координатам (15, 200)
            ; Click 15, 540
            ; Sleep(100)

            Click 1200, 540
            ; Sleep(100)

            Send("+!s")
            Sleep(500)

            Send("5")
        }
    }
}

^!+F6:: {
    ; Проверяем, активен ли Chrome
    if WinActive("ahk_exe chrome.exe") {
        ; Получаем заголовок активного окна
        title := WinGetTitle("A")

        ; Проверяем, содержит ли заголовок слово "Reading"
        if InStr(title, "Reading", false) || InStr(title, "Translate", false) {
            ; Шаг 1: Задержка перед отправкой комбинации клавиш (например, 500 миллисекунд)
            Sleep(500)

            ; Шаг 4: Получаем текущую позицию мыши
            MouseGetPos(&xpos, &ypos)

            ; Шаг 5: Двигаем указатель мыши на 1024 пикселя вправо
            MouseMove(xpos + 1024, ypos, 0)

            ; Шаг 6: Возвращаем указатель в исходное положение
            MouseMove(xpos, ypos, 0)
            Sleep(500)

            ; Кликаем по координатам (15, 200)
            ; Click 15, 540
            ; Sleep(100)

            ; Click 1000, 500
            ; Sleep(100)

            ; Send("+!s")
            ; Sleep(500)

            Click 15, 540
            Send("w")

            Click 1200, 540
        }
    }
}

^!+F7:: {
    ; Проверяем, активен ли Chrome
    if WinActive("ahk_exe chrome.exe") || InStr(title, "Translate", false) {
        ; Получаем заголовок активного окна
        title := WinGetTitle("A")

        ; Проверяем, содержит ли заголовок слово "Reading"
        if InStr(title, "Reading", false) {
            ; Шаг 1: Задержка перед отправкой комбинации клавиш (например, 500 миллисекунд)
            Sleep(500)

            ; Шаг 4: Получаем текущую позицию мыши
            MouseGetPos(&xpos, &ypos)

            ; Шаг 5: Двигаем указатель мыши на 1024 пикселя вправо
            MouseMove(xpos + 1024, ypos, 0)

            ; Шаг 6: Возвращаем указатель в исходное положение
            MouseMove(xpos, ypos, 0)
            Sleep(500)

            ; Кликаем по координатам (15, 200)
            ; Click 15, 540
            ; Sleep(100)

            ; Click 1000, 500
            ; Sleep(100)

            ; Send("+!s")
            ; Sleep(500)

            Click 15, 540
            Send("i")

            Click 1200, 540
        }
    }
}

^!+F8:: {
    ; Проверяем, активен ли Chrome
    if WinActive("ahk_exe chrome.exe") || InStr(title, "Translate", false) {
        ; Получаем заголовок активного окна
        title := WinGetTitle("A")

        ; Проверяем, содержит ли заголовок слово "Reading"
        if InStr(title, "Reading", false) {
            ; Шаг 1: Задержка перед отправкой комбинации клавиш (например, 500 миллисекунд)
            Sleep(500)

            ; Шаг 4: Получаем текущую позицию мыши
            MouseGetPos(&xpos, &ypos)

            ; Шаг 5: Двигаем указатель мыши на 1024 пикселя вправо
            MouseMove(xpos + 1024, ypos, 0)

            ; Шаг 6: Возвращаем указатель в исходное положение
            MouseMove(xpos, ypos, 0)
            Sleep(500)

            ; Кликаем по координатам (15, 200)
            ; Click 15, 540
            ; Sleep(100)

            ; Click 1000, 500
            ; Sleep(100)

            ; Send("+!s")
            ; Sleep(500)

            Click 15, 540
            Send("x")

            Click 1200, 540
        }
    }
}
; ^!+:: {
;     if WinActive("ahk_exe chrome.exe") && InStr(WinGetTitle("A"), "Reading") {
;         ; Step 1: Delay before sending the key combination (e.g., 500 milliseconds)
;         Sleep(500)

;         ; Step 4: Get the current mouse position
;         MouseGetPos(&xpos, &ypos)

;         ; Step 5: Move the mouse pointer 1024 pixels to the right
;         MouseMove(xpos + 1024, ypos, 0)

;         ; Step 6: Return the pointer to the original position
;         MouseMove(xpos, ypos, 0)

;         Sleep(500)

;         Send("w")
;     }
; }
