; AHK v2 syntax

^!+1::
{
    Send("^c")
    ClipWait(1) ; Ждем, пока в буфере обмена появятся данные
    Sleep(100)

    ; --- НАЧАЛО НОВОГО БЛОКА ЛОГИКИ ---
    ; Ищем главное окно GoldenDict-ng по его ширине
    
    main_gd_id := 0
    ; Получаем список всех окон, принадлежащих процессу goldendict.exe
    gd_windows := WinGetList("ahk_exe goldendict.exe")

    for id in gd_windows
    {
        WinGetPos(,, &width,, id) ; Получаем ширину каждого окна
        ; Предполагаем, что главное окно всегда шире 400 пикселей.
        ; Боковое окно обычно значительно уже.
        if (width > 400)
        {
            main_gd_id := id ; Сохраняем ID главного окна
            break ; Прерываем цикл, так как мы нашли то, что искали
        }
    }

    ; Активируем главное окно, если оно было найдено
    if main_gd_id
    {
        WinActivate(main_gd_id)
        WinWaitActive(main_gd_id,, 2) ; Ждем активации окна (до 2 секунд)
    }
    else
    {
        ; Если GoldenDict не запущен, можно его запустить (опционально)
        ; Run("goldendict.exe")
        ; WinWait("ahk_exe goldendict.exe",, 5)
        ; Либо просто продолжить, как в вашем старом скрипте
        WinActivate("ahk_exe goldendict.exe")
    }
    ; --- КОНЕЦ НОВОГО БЛОКА ЛОГИКИ ---

    ; Ваш оригинальный код для выполнения поиска
    Send("^m")
    Sleep(100)

    ; Вариант с удалением переносов строк через Python
    RunWait('C:\Python\Python312\python.exe "C:\Tools\remove_newline_util\remove_newline_util.py"', '', 'Hide')
    Sleep(750)

    Send("^v")
    Sleep(100)

    ; Отправка данных из поля
    Send("{Enter}")
}