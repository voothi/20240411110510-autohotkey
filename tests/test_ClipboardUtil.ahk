#Requires AutoHotkey v2.0
#Include "..\Lib\ClipboardUtil.ahk"

/**
 * Automated tests for ClipboardUtil.ahk (ZID: 20260515094621)
 */

; Test 1: Hyphenation and Conjunctions
test_data := "This is a compo-`r`nund compositional word.`r`nAnd this is a simple hyphen-`r`nated word."
cleaned := CleanClipboardText(test_data)
expected := "This is a compo- und compositional word. And this is a simple hyphenated word."

if (cleaned == expected) {
    FileAppend("SUCCESS: Text cleaned correctly.`n", "*")
} else {
    FileAppend("FAILURE: Text cleaning failed.`nExpected: " . expected . "`nGot:      " . cleaned . "`n", "*")
}

; Test 2: HTML and Spaces
test_html := "Word with <b>tags</b> and  multiple   spaces."
cleaned_html := CleanClipboardText(test_html)
expected_html := "Word with tags and multiple spaces."

if (cleaned_html == expected_html) {
    FileAppend("SUCCESS: HTML and spaces cleaned correctly.`n", "*")
} else {
    FileAppend("FAILURE: HTML cleaning failed.`nGot: " . cleaned_html . "`n", "*")
}

; Test 3: Non-printable characters and Punctuation
test_nonprint := "Clean: " . Chr(0x07) . "Text   ! "
cleaned_np := CleanClipboardText(test_nonprint)
expected_np := "Clean: Text!"

if (cleaned_np == expected_np) {
    FileAppend("SUCCESS: Non-printable and punctuation cleaned correctly.`n", "*")
} else {
    FileAppend("FAILURE: Non-printable cleaning failed.`nGot: " . cleaned_np . "`n", "*")
}

; Test 4: Case Conversion
A_Clipboard := "<b>HELLlo</b> World"
cleaned_case := ConvertClipboardCase("lower")
expected_case := "helllo world"

if (cleaned_case == expected_case) {
    FileAppend("SUCCESS: Case conversion worked.`n", "*")
} else {
    FileAppend("FAILURE: Case conversion failed.`nGot: " . cleaned_case . "`n", "*")
}
