## Why

Clipboard synchronization between `kardenwort-mpv` and GoldenDict (via AHK) was prone to race conditions and keyboard layout conflicts (EN/RU). Character-based hotkey injection often resulted in "garbage" text (e.g., `q`, `й`) appearing in search fields, while AHK polling introduced unpredictable latency.

## What Changes

- **Harden AHK Timing**: Standardized `ClipWait` timeouts in `gd-side.ahk` and `gd-main.ahk` to handle OS-level clipboard propagation.
- **In-process AHK Cleaning**: Consolidated newline and hyphen cleaning directly into AHK to reduce subprocess overhead.
- **Layout-Independent VK Engine (MPV)**: Implemented raw Win32 `keybd_event` injection in the MPV host (PowerShell-based) to ensure the trigger works identically across EN/RU layouts.
- **Dual-Mode Dictionary Notification**: Added support for independent notification paths for "Popup" and "Main Window" modes using standardized `gd_` naming.

## Capabilities

### New Capabilities
- `goldendict-bridge-latency`: Establishes a robust timing contract between the MPV host and AHK/GoldenDict observers.
- `automated-utility-testing`: Standardizes the location and naming of verification scripts for shared libraries.

### Modified Capabilities
- `unified-clipboard-abstraction`: Updated with a high-reliability, layout-agnostic, multi-mode notification engine.

## Impact

- **Affected Code**: `gd-side.ahk`, `gd-main.ahk`, `lls_core.lua`.
- **UX**: 100% reliable dictionary popups regardless of active keyboard layout, with zero "garbage" characters and significantly reduced latency.
