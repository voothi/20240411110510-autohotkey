# Personal AutoHotkey v2 Script Collection

> **Note:** This is a development version. These scripts are highly personalized for a specific workflow and contain hardcoded paths. They are intended as a reference or starting point. You will need to modify them to work on your system.

This repository is a collection of personal [AutoHotkey v2](https://www.autohotkey.com/) scripts designed to automate various tasks across different applications, including Anki, GoldenDict, Obsidian, and more. Many scripts rely on external Python utilities for text processing.

## Table of Contents

- [Personal AutoHotkey v2 Script Collection](#personal-autohotkey-v2-script-collection)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Scripts](#scripts)
    - [anki-browser-button.ahk](#anki-browser-buttonahk)
    - [anki-review-button.ahk](#anki-review-buttonahk)
    - [autoswitch.ahk](#autoswitchahk)
    - [button1.ahk](#button1ahk)
    - [button2.ahk](#button2ahk)
    - [focus-on-left-app.ahk](#focus-on-left-appahk)
    - [focus-on-right-app.ahk](#focus-on-right-appahk)
    - [gd-find.ahk](#gd-findahk)
    - [gd-main.ahk](#gd-mainahk)
    - [gd-side.ahk](#gd-sideahk)
    - [hotkeys.ahk](#hotkeysahk)
    - [kill-ffplay.ahk](#kill-ffplayahk)
    - [lowercase.ahk](#lowercaseahk)
    - [lute.ahk](#luteahk)
    - [obsidian-zid-wikilink.ahk](#obsidian-zid-wikilinkahk)
    - [open-in-anki.ahk](#open-in-ankiahk)
    - [remove-newline.ahk](#remove-newlineahk)
    - [tts.ahk](#ttsahk)
    - [uppercase.ahk](#uppercaseahk)
    - [vocabsieve-anki-desk.ahk](#vocabsieve-anki-deskahk)
    - [vocabsieve-save.ahk](#vocabsieve-saveahk)
    - [whisper.ahk](#whisperahk)
    - [zid-name.ahk](#zid-nameahk)
    - [zid.ahk](#zidahk)
  - [Kardenwort Ecosystem](#kardenwort-ecosystem)
  - [License](#license)

## Prerequisites

1.  **AutoHotkey v2.0+**: All scripts are written for AHK v2 and are not compatible with v1.
2.  **Python 3**: Many scripts call external Python utilities for text manipulation. You must have Python installed and available in your system's PATH.
3.  **Hardcoded Paths**: **This is critical.** Most scripts that use Python have hardcoded paths (e.g., `C:\Python\Python312\python.exe`, `C:\Tools\...`). You **must** edit these scripts and update the paths to match your own file system structure.

[Back to Top](#table-of-contents)

## Scripts

### anki-browser-button.ahk
- **Description:** When Anki's "Preview" window is active, this script finds the main "Browse" window, sends a keystroke to it, and then returns focus back to the Preview window. This allows for quick actions on a card without leaving the preview.
- **Hotkeys:**
  - `Ctrl + K`: Sends `Ctrl+K` to the Browse window.
  - `Ctrl + J`: Sends `Ctrl+J` to the Browse window.
- **Context:** Only active when an Anki "Preview" window is focused.

[Back to Top](#table-of-contents)

### anki-review-button.ahk
- **Description:** Triggers a UI refresh within Anki. This is useful when an add-on or a part of the interface doesn't update correctly. It sends a key combination and performs a rapid mouse movement to force a redraw.
- **Hotkey:** `Ctrl + Alt + R`
- **Context:** Only active when an Anki window is focused.

[Back to Top](#table-of-contents)

### autoswitch.ahk
- **Description:** Automatically switches the keyboard layout to English when specific applications (GoldenDict, PotPlayer) or specific Chrome tabs (containing "Reading", "Translate", etc.) are active.
- **Hotkey:** None (runs automatically in the background).

[Back to Top](#table-of-contents)

### button1.ahk
- **Description:** An advanced remapper for a specific mouse button (`sc028`). It provides multiple functions based on user action: single-click, double-click, drag, and an automatic scroll-down feature if the button is held without moving the mouse.
- **Hotkey:** `Ctrl + Alt + Shift + sc028` (custom button scan code).

[Back to Top](#table-of-contents)

### button2.ahk
- **Description:** A simple short-press vs. long-press remapper for a button (`sc01A`). Tapping the button performs a right-click, while holding it down initiates a continuous scroll-up.
- **Hotkey:** `Ctrl + Alt + Shift + sc01A` (custom button scan code).

[Back to Top](#table-of-contents)

### focus-on-left-app.ahk
- **Description:** Moves the mouse cursor a fixed pixel distance to the left. Designed for multi-monitor setups to quickly jump the cursor to an application on the left monitor. The pixel distance is hardcoded and must be adjusted for your setup.
- **Hotkey:** `Ctrl + Alt + G`

[Back to Top](#table-of-contents)

### focus-on-right-app.ahk
- **Description:** Moves the mouse cursor a fixed pixel distance to the right. Designed for multi-monitor setups to quickly jump the cursor to an application on the right monitor. The pixel distance is hardcoded and must be adjusted for your setup.
- **Hotkey:** `Ctrl + Alt + H`

[Back to Top](#table-of-contents)

### gd-find.ahk
- **Description:** A "smart find" script for GoldenDict. The first time you press the hotkey with text selected, it starts a new search. Subsequent presses with the same text selected (or nothing selected) will trigger "Find Next" (F3).
- **Hotkey:** `Ctrl + G`
- **Context:** Only active when a GoldenDict window is focused.

[Back to Top](#table-of-contents)

### gd-main.ahk
- **Description:** A complex macro to look up selected text in the main GoldenDict window. It intelligently finds/activates the main window, cleans the selected text by removing newlines via a Python script, and pastes it into the search bar.
- **Hotkey:** `Ctrl + Alt + Shift + 1`
- **Dependencies:** Requires a corresponding Python script (`remove_newline_util.py`) at a hardcoded path.

[Back to Top](#table-of-contents)

### gd-side.ahk
- **Description:** Looks up the selected text using GoldenDict's "scan pop-up" feature. It first copies the text, cleans it by removing newlines via a Python script, and then triggers GoldenDict's global pop-up hotkey.
- **Hotkey:** `Ctrl + Alt + Shift + Q`
- **Dependencies:** Requires a Python script (`remove_newline_util.py`) and assumes GoldenDict's pop-up hotkey is configured to `^!+n`.

[Back to Top](#table-of-contents)

### hotkeys.ahk
- **Description:** Remaps Enter and Ctrl+Enter specifically for the Google AI Studio web interface. This inverts the default behavior, making `Enter` create a new line and `Ctrl+Enter` submit the prompt.
- **Hotkeys:**
  - `Enter`: Sends `Shift+Enter`.
  - `Ctrl + Enter`: Sends `Enter`.
- **Context:** Only active in a Chrome window with "Google AI Studio" in the title.

[Back to Top](#table-of-contents)

### kill-ffplay.ahk
- **Description:** A global hotkey to instantly terminate all running instances of `ffplay.exe`. Useful for closing audio/video previews launched by other programs like GoldenDict.
- **Hotkey:** `Ctrl + Alt + Shift + 0`

[Back to Top](#table-of-contents)

### lowercase.ahk
- **Description:** Copies the selected text, processes it with an external Python script to convert it to lowercase, and pastes the result back, replacing the original selection.
- **Hotkey:** `Ctrl + Alt + I`
- **Dependencies:** Requires a corresponding Python script (`lowercase_util.py`) at a hardcoded path.

[Back to Top](#table-of-contents)

### lute.ahk
- **Description:** A set of helper hotkeys for the "Lute" web application. It allows sending commands to the main "Reading" tab even when focused on a related "Translate" tab by automatically switching windows, sending the command, and sometimes switching back.
- **Hotkeys:** `^!+F1` through `^!+F8`, `^!+a`, `^!+d`.

[Back to Top](#table-of-contents)

### obsidian-zid-wikilink.ahk
- **Description:** Formats the selected text into an Obsidian Zettelkasten ID (ZID) wikilink. It copies the text, uses a Python script to prepend a timestamp and add wikilink brackets (e.g., `[[YYYYMMDDHHMMSS My Note]]`), and pastes the result.
- **Hotkey:** `Ctrl + Alt + .`
- **Dependencies:** Requires a corresponding Python script (`obsidian_zid_wikilink.py`) at a hardcoded path.

[Back to Top](#table-of-contents)

### open-in-anki.ahk
- **Description:** Searches for the selected text in Anki's card browser. It can be triggered manually via a hotkey within GoldenDict, or via the command line for integration with external programs.
- **Hotkey:** `Ctrl + Alt + A` (within GoldenDict).
- **Dependencies:** Requires a corresponding Python script (`anki-search.py`) at a hardcoded path.

[Back to Top](#table-of-contents)

### remove-newline.ahk
- **Description:** Copies the selected text, processes it with an external Python script to remove all newline characters, and pastes the result back as a single line. Excellent for cleaning text from PDFs.
- **Hotkey:** `Ctrl + Alt + N`
- **Dependencies:** Requires a corresponding Python script (`remove_newline_util.py`) at a hardcoded path.

[Back to Top](#table-of-contents)

### tts.ahk
- **Description:** Provides multi-language Text-to-Speech for selected text. It uses separate hotkeys to read text aloud in English, German, or Russian by passing it to an external Python script that interfaces with the Piper TTS engine.
- **Hotkeys:**
  - `Ctrl + Alt + Shift + 2`: Read in English.
  - `Ctrl + Alt + Shift + 3`: Read in German.
  - `Ctrl + Alt + Shift + 4`: Read in Russian.
- **Dependencies:** Requires a corresponding Python script (`piper_tts.py`) at a hardcoded path.

[Back to Top](#table-of-contents)

### uppercase.ahk
- **Description:** Copies the selected text, processes it with an external Python script to convert it to UPPERCASE, and pastes the result back, replacing the original selection.
- **Hotkey:** `Ctrl + Alt + U`
- **Dependencies:** Requires a corresponding Python script (`uppercase_util.py`) at a hardcoded path.

[Back to Top](#table-of-contents)

### vocabsieve-anki-desk.ahk
- **Description:** Automates sending an entry from the Vocabsieve application to Anki. It triggers the export and navigates the subsequent Anki dialog to pre-select a specific deck/note type.
- **Hotkey:** `Ctrl + Alt + O`
- **Context:** Only active when a Vocabsieve window is focused.

[Back to Top](#table-of-contents)

### vocabsieve-save.ahk
- **Description:** Automates the "Save As" workflow in Vocabsieve. It copies the content from a text field and automatically uses it as the filename in the "Save As" dialog.
- **Hotkey:** `Ctrl + Alt + S`

[Back to Top](#table-of-contents)

### whisper.ahk
- **Description:** A simple hotkey forwarder. It captures `Ctrl+Alt+Shift+E` and sends `Ctrl+Alt+E`. This is useful for remapping a hotkey for another application.
- **Hotkey:** `Ctrl + Alt + Shift + E`

[Back to Top](#table-of-contents)

### zid-name.ahk
- **Description:** Formats the selected text into a Zettelkasten ID (ZID) note title. It copies the text, uses a Python script to prepend a timestamp (e.g., `YYYYMMDDHHMMSS My Note`), and pastes the result.
- **Hotkey:** `Ctrl + Alt + ;`
- **Dependencies:** Requires a corresponding Python script (`zid_name.py`) at a hardcoded path.

[Back to Top](#table-of-contents)

### zid.ahk
- **Description:** A simple utility to insert a timestamp in the format `YYYYMMDDHHMMSS`. Ideal for creating unique identifiers for notes or files.
- **Hotkey:** `Ctrl + Shift + /`

[Back to Top](#table-of-contents)

## Kardenwort Ecosystem

This project is part of the **[Kardenwort](https://github.com/kardenwort)** environment, designed to create a focused and efficient learning ecosystem.

[Back to Top](#table-of-contents)

## License

This project is licensed under the MIT License.

[Back to Top](#table-of-contents)
