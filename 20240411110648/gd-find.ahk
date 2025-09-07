#Requires AutoHotkey v2.0

; =================================================================
; Умный скрипт для поиска в GoldenDict
; Активация: Ctrl+G (можно изменить)
;
; Логика:
; 1. Если выделили НОВОЕ слово и нажали хоткей:
;    - Скрипт выполнит поиск этого слова (Ctrl+C, Ctrl+F, Ctrl+V).
; 2. Если вы нажали хоткей ПОВТОРНО (для того же слова):
;    - Скрипт нажмет F3 (Найти далее).
; =================================================================

#HotIf WinActive("ahk_exe goldendict.exe")

; Используем функцию, чтобы хранить последнее искомое слово
^g::FindNextInGoldenDict()

FindNextInGoldenDict()
{
    ; Статическая переменная сохраняет свое значение между вызовами функции
    static lastSearchTerm := ""
    
    savedClip := A_Clipboard
    A_Clipboard := ""

    Sleep(500)
    Send("^c")
    
    if ClipWait(0.5)
    {
        currentSelection := A_Clipboard

        ; Если текущее выделение совпадает с последним поиском
        ; (и не пустое), то просто ищем следующее вхождение
        if (currentSelection == lastSearchTerm && currentSelection != "")
        {
            Send("{F3}") ; F3 - стандартная клавиша "Найти далее"
        }
        else ; Иначе - это новый поиск
        {
            lastSearchTerm := currentSelection ; Запоминаем новое слово
            Send("^f")
            Sleep(150)
            Send("^v") ; или Send(currentSelection)
            Send("{Enter}")
        }
    }
    else
    {
        ; Если ничего не было скопировано (например, ничего не выделено),
        ; но мы уже что-то искали, то тоже нажимаем F3.
        if (lastSearchTerm != "")
        {
            Send("{F3}")
        }
    }

    A_Clipboard := savedClip
}

#HotIf