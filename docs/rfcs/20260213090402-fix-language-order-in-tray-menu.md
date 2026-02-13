20260213090402
20260213091653

# RFC: Fix Language Order in Tray Menu

## Problem
The order of languages in the context menu of the tray icon did not match the order specified in `config.ini`. Instead, it appeared in alphabetical order.

## Analytics
In AutoHotkey v2, the `Map` object is used for storing key-value pairs (language code to info). Iterating over a `Map` using a `for` loop does not guarantee insertion order; in many cases, it follows alphabetical order.

The script already maintained a `langCodes` array which stores the language codes in the order they are read from the configuration file.

## Decisions
- **Iterate over Array**: Update `UpdateTrayMenu()` to iterate over the `langCodes` array instead of the `langInfo` map. This ensures that the menu items are added in the same order as they appear in the `config.ini` file.
- **Improved Testing**: Added a specific test case in the automated test suite (`tests/test_tts.ahk`) to verify that the `langCodes` array preserves the configuration order. This prevents future regressions.

## Implementation Details

### `tts/tts.ahk`
Updated the `UpdateTrayMenu` function:
```autohotkey
    for code in langCodes {
        info := langInfo[code]
        A_TrayMenu.Add(info.text " (" code ")", ((c, *) => SetLanguage(c)).Bind(code))
    }
```

### `tts/tests/test_tts.ahk`
Added assertions to verify the ordering of the `langCodes` array:
```autohotkey
Assert(langCodes[1] == "en", "Order 1: en")
Assert(langCodes[2] == "de", "Order 2: de")
Assert(langCodes[3] == "ru", "Order 3: ru")
Assert(langCodes[4] == "uk", "Order 4: uk")
```
and updated the cycle test to include the new `uk` language added to the test configuration.
