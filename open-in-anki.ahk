#Requires AutoHotkey v2.0

; Позволяет запускать несколько экземпляров этого скрипта одновременно.
#SingleInstance Off 

; --- Пути к вашим файлам ---
pythonPath := "C:\Python\Python312\python.exe"
scriptPath := "C:\Tools\anki-search\anki-search.py"

; ===================================================================
; === РЕЖИМ 1: Запуск из GoldenDict с ключом /trigger ===
; ===================================================================
if A_Args.Length > 0 && A_Args[1] == "/trigger"
{
    ; GoldenDict уже скопировал выделенный текст в буфер обмена.
    ; Мы просто выполняем основное действие.
    RunPythonAndActivateAnki()
    ExitApp ; Важно: закрываем этот временный экземпляр скрипта.
}

; ===================================================================
; === РЕЖИМ 2: Фоновый режим с горячей клавишей ===
; ===================================================================
#HotIf WinActive("ahk_exe goldendict.exe")
^!a::
{
    ; Сохраняем буфер обмена, чтобы не испортить его.
    ; local savedClipboard := A_ClipboardAll
    
    ; Копируем выделенный текст.
    A_Clipboard := ""
    SendInput("^c")
    
    if !ClipWait(1)
        Return

    ; Выполняем основное действие.
    RunPythonAndActivateAnki()

    ; Возвращаем исходный буфер обмена.
    ; Sleep(300)
    ; A_Clipboard := savedClipboard
}
#HotIf

; ===================================================================
; === ОСНОВНАЯ ФУНКЦИЯ, которая делает всю работу ===
; ===================================================================
RunPythonAndActivateAnki()
{
    ; Формируем команду и запускаем Python-скрипт (он читает буфер обмена).
    local command := '"' . pythonPath . '" "' . scriptPath . '" --browse-clipboard'
    Run(command,, "Hide")

    ; Ждём появления окна браузера Anki и активируем его.
    if WinWait("Browse ahk_exe anki.exe",, 2)
    {
        WinActivate("Browse ahk_exe anki.exe")
    }
}