## 1. AHK Bridge Hardening

- [x] 1.1 Increase `ClipWait` timeout to 3 seconds in `gd-side.ahk`
- [x] 1.2 Increase `ClipWait` timeout to 3 seconds in `gd-main.ahk`
- [x] 1.3 Implement German-aware hyphenation and newline cleaning logic in AHK (port from `remove_newline_util.py`)
- [x] 1.4 Remove external Python script calls from `gd-side.ahk` and `gd-main.ahk`

## 2. MPV Clipboard Optimization

- [x] 2.1 Update `Options` in `lls_core.lua` to include `goldendict_trigger` (default: `no`)
- [x] 2.2 Refactor `set_clipboard` in `lls_core.lua` to prioritize `mp.set_property("clipboard", text)` with PowerShell fallback
- [x] 2.3 Implement optional post-copy hotkey trigger (`^!+n`) in `cmd_copy_sub` and `cmd_dw_copy`
- [x] 2.4 Synchronize `mpv.conf` with new clipboard options and recommended retry parameters

## 3. Verification & Cleanup

- [x] 3.1 Verify lookup reliability from MPV (Drum Window and OSD) with the new AHK bridge
- [x] 3.2 Verify that German hyphenated words are correctly joined in GoldenDict
- [x] 3.3 Verify PowerShell fallback works if native clipboard setting is forced to fail (test case)
- [x] 3.4 (Optional) Archive `remove_newline_util.py` if no longer used by other scripts
