## Context

The current bridge between `kardenwort-mpv` and GoldenDict AHK scripts relies on high-latency PowerShell commands to update the system clipboard. This latency (~800ms) often exceeds the 1-second timeout in the AHK scripts, causing GoldenDict to miss the update or display stale data. Furthermore, the AHK script uses an external Python script for simple text cleaning, adding unnecessary subprocess overhead.

## Goals / Non-Goals

**Goals:**
- Eliminate the race condition by increasing AHK timeouts and decreasing MPV copy latency.
- Reduce system overhead by porting Python-based text cleaning logic into AHK.
- Improve GoldenDict responsiveness by optionally triggering its popup directly from the host application.

**Non-Goals:**
- Completely rewriting the AHK scripts or GoldenDict itself.
- Changing the internal data structures of `lls_core.lua` beyond clipboard handling.

## Decisions

### 1. Increase AHK `ClipWait` Timeout
- **Decision**: Increase `ClipWait` from `1` to `3` in `gd-side.ahk` and `gd-main.ahk`.
- **Rationale**: 3 seconds is sufficient to cover even the slowest PowerShell startup and retry loops, ensuring the script doesn't give up before the data arrives.

### 2. In-Process AHK Text Cleaning
- **Decision**: Implement the logic from `remove_newline_util.py` using AHK `RegExReplace`.
- **Rationale**: Eliminates the overhead of starting a Python interpreter and two extra clipboard operations (Read/Write), making the bridge faster and more robust.

### 3. Native MPV Clipboard Support
- **Decision**: Update `lls_core.lua` to prioritize `mp.set_property("clipboard", text)`.
- **Rationale**: This is a nearly zero-latency operation compared to PowerShell. We will keep PowerShell as a fallback for systems where the native property is unavailable.

### 4. Optional Post-Copy GoldenDict Trigger
- **Decision**: Add a `lls-goldendict_trigger` option (default `no`) to `lls_core.lua` to send `^!+n` after copying.
- **Rationale**: Directly triggering the popup from the copy source ensures the lookup happens even if the AHK observer fails or if GoldenDict's internal clipboard monitor is disabled.

## Risks / Trade-offs

- **[Risk] Native Clipboard Failure** → **Mitigation**: Implement a robust fallback to PowerShell if the native property call fails or is unsupported.
- **[Risk] AHK Regex Parity** → **Mitigation**: Carefully port the Python regexes (especially German hyphenation) to AHK's PCRE engine and verify with test cases.
- **[Risk] Duplicate Popups** → **Mitigation**: If both MPV and AHK trigger the popup, GoldenDict might flicker. Recommendation: Disable AHK trigger if using MPV trigger.
