## 1. AHK Bridge Hardening

- [x] 1.1 Increase `ClipWait` timeout to 3 seconds in `gd-side.ahk` and `gd-main.ahk`
- [x] 1.2 Implement German-aware hyphenation and newline cleaning in native AHK
- [x] 1.3 Remove external Python script dependencies from AHK scripts
- [x] 1.4 Synchronize naming conventions (`gd_`, `dw_`) across AHK scripts

## 2. MPV Host Integration (VK Engine)

- [x] 2.1 Implement `gd_` prefix naming convention in `lls_core.lua`
- [x] 2.2 Implement dual-mode lookup support (`side` vs `main`) in MPV host
- [x] 2.3 Implement Win32 `keybd_event` VK-based injection engine in MPV
- [x] 2.4 Refactor `set_clipboard` to be layout-independent and non-blocking (async)
- [x] 2.5 Register global `Ctrl+Alt+C` binding for main dictionary window

## 3. Verification & Testing

- [x] 3.1 Verify reliable triggering in EN/RU layouts (Zero garbage injection)
- [x] 3.2 Verify that German hyphenated words are correctly joined in AHK
- [x] 3.3 Verify non-blocking operation (no MPV stutter during trigger)
- [x] 3.4 Establish root `tests/` directory and migrate `test_ClipboardUtil.ahk`
