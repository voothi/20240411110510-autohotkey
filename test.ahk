#Requires AutoHotkey v2.0
text := "finished processing, whereas .23, .25, and .27 were"
text := RegExReplace(text, "\s+([:;,!?])", "$1")
FileAppend(text "
", "output.txt")
text := RegExReplace(text, "\s+\.(?!\w)", ".")
FileAppend(text "
", "output.txt")
