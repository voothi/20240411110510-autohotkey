## 1. AHK Bridge Hardening

- [ ] 1.1 Increase `ClipWait` timeout to 3 seconds in `gd-side.ahk`
- [ ] 1.2 Increase `ClipWait` timeout to 3 seconds in `gd-main.ahk`
- [ ] 1.3 Implement German-aware hyphenation and newline cleaning logic in AHK (port from `remove_newline_util.py`)
- [ ] 1.4 Remove external Python script calls from `gd-side.ahk` and `gd-main.ahk`

## 2. MPV Clipboard Optimization

- [ ] 2.1 Update `Options` in `lls_core.lua` to include `goldendict_trigger` (default: `no`)
- [ ] 2.2 Refactor `set_clipboard` in `lls_core.lua` to prioritize `mp.set_property("clipboard", text)` with PowerShell fallback
- [ ] 2.3 Implement optional post-copy hotkey trigger (`^!+n`) in `cmd_copy_sub` and `cmd_dw_copy`
- [ ] 2.4 Synchronize `mpv.conf` with new clipboard options and recommended retry parameters

## 3. Verification & Cleanup

- [ ] 3.1 Verify lookup reliability from MPV (Drum Window and OSD) with the new AHK bridge
- [ ] 3.2 Verify that German hyphenated words are correctly joined in GoldenDict
- [ ] 3.3 Verify PowerShell fallback works if native clipboard setting is forced to fail (test case)
- [ ] 3.4 (Optional) Archive `remove_newline_util.py` if no longer used by other scripts
