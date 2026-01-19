20260119121949

# RFC: Migrate TTS Engine to anki-tts-cli and Add Ukrainian Support

## Staging
ZID: 20260119121949

## Implementation Details

### Analytics
The previous Text-to-Speech implementation in `tts.ahk` relied on a Piper TTS wrapper script (`piper_tts.py`) developed in the `20241206010110-piper-tts` project. A new utility, `anki-tts-cli`, has been introduced in `20260119103526-anki-tts-cli` to provide a more streamlined CLI for Anki-compatible TTS processing. This migration requires updating the executable path and transitioning from flag-based arguments (`--lang`, `--clipboard`) to positional arguments (`"text"`, `"lang"`).

### Decisions
1.  **Backend Migration**: Updated the `RunWait` command in `tts.ahk` to point to `U:\voothi\20260119103526-anki-tts-cli\anki-tts-cli.py`.
2.  **Argument Pattern Change**: Switched to passing the clipboard content and language code as positional arguments to align with the new CLI's interface.
3.  **Language Expansion**: Added a new hotkey `Ctrl+Alt+Shift+5` for Ukrainian (`uk`) support.
4.  **Metadata Alignment**: Updated script headers and `README.md` to reflect the dependency on the new `anki-tts-cli` repository.
