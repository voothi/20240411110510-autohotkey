#Requires AutoHotkey v2.0
#Include "..\Lib\ClipboardUtil.ahk"

/**
 * Automated tests for ClipboardUtil.ahk (ZID: 20260503133011)
 */

test_data := "This is a compo-`r`nund compositional word.`r`nAnd this is a simple hyphen-`r`nated word."
cleaned := CleanClipboardText(test_data)

expected := "This is a compo- und compositional word. And this is a simple hyphenated word."

if (cleaned == expected) {
    FileAppend("SUCCESS: Text cleaned correctly.`nResult: " . cleaned . "`n", "*")
} else {
    FileAppend("FAILURE: Text cleaning failed.`nExpected: " . expected . "`nGot:      " . cleaned . "`n", "*")
}

test_html := "Word with <b>tags</b> and  multiple   spaces."
cleaned_html := CleanClipboardText(test_html)
expected_html := "Word with tags and multiple spaces."

if (cleaned_html == expected_html) {
    FileAppend("SUCCESS: HTML and spaces cleaned correctly.`n", "*")
} else {
    FileAppend("FAILURE: HTML cleaning failed.`nGot: " . cleaned_html . "`n", "*")
}
