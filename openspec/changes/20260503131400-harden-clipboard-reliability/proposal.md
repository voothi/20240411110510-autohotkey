## Why

When using `kardenwort-mpv` on Windows, clipboard synchronization with GoldenDict occasionally fails (the window doesn't appear or shows stale data). This is due to a race condition where the high-latency PowerShell-based copy operation (~800ms) exceeds the 1-second timeout in the companion AutoHotkey scripts, leading to synchronization "gaps" and missed lookups.

## What Changes

- **Harden AHK Timing**: Increase the `ClipWait` timeout in GoldenDict-related AHK scripts (`gd-side.ahk`, `gd-main.ahk`) to handle PowerShell startup latency.
- **In-process AHK Cleaning**: Port regex-based newline and hyphen cleaning from the external Python script directly into AHK to reduce subprocess overhead and clipboard locking roundtrips.
- **Native Clipboard Setting (Experimental)**: Introduce support for MPV's native `mp.set_property("clipboard", ...)` in `lls_core.lua` to bypass PowerShell latency where supported.
- **Direct Lookup Trigger**: Add an optional configuration to `lls_core.lua` to explicitly trigger the GoldenDict scan popup hotkey after a successful copy.

## Capabilities

### New Capabilities
- `goldendict-bridge-latency`: Establishes a robust timing contract between the MPV host and AHK/GoldenDict observers.

### Modified Capabilities
- `unified-clipboard-abstraction`: Update `set_clipboard` to support faster native setting and optional post-copy hotkey triggers.

## Impact

- **Affected Code**: `gd-side.ahk`, `gd-main.ahk`, `lls_core.lua`.
- **Dependencies**: Reduces reliance on external `remove_newline_util.py`.
- **UX**: Eliminates "missed" lookups and reduces the time between a copy action in MPV and the GoldenDict popup appearing.
