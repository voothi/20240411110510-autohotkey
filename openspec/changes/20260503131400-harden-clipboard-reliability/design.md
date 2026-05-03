## Context

The bridge between `kardenwort-mpv` and GoldenDict was prone to race conditions and keyboard layout inconsistencies (EN/RU). Character-based hotkey injection often resulted in "garbage" text (e.g., `q`, `й`) appearing in search fields, while AHK polling introduced unpredictable latency.

## Goals / Non-Goals

**Goals:**
- Provide a 100% layout-independent trigger for GoldenDict (EN/RU).
- Support dual-mode lookups (Side Popup vs. Main Window).
- Eliminate "garbage" character injection (`q`, `й`) during hotkey triggering.
- Port Python-based text cleaning logic into native AHK for performance.

**Non-Goals:**
- Modifying GoldenDict's internal logic.

## Decisions

### 1. Standardized Naming (Cross-Project)
- **Decision**: Adopt the `gd_` prefix for bridge settings and `dw_` for trigger keys in both MPV and AHK contexts.
- **Rationale**: Ensures consistency and clarity when configuring the system across multiple tools.

### 2. Layout-Independent VK Injection
- **Decision**: In the MPV host, use Win32 `keybd_event` via PowerShell to send raw Virtual Key (VK) signals.
- **Rationale**: Unlike character-based triggers, VK signals are layout-agnostic and prevent search field pollution.

### 3. Dual-Mode Dictionary Notification
- **Decision**: Implement independent notification paths for "Popup" (side) and "Main Window" lookups.
- **Rationale**: Matches the existing AHK architecture while providing precise control from the player host.

### 4. Native AHK Text Cleaning
- **Decision**: Implement the logic from `remove_newline_util.py` using AHK `RegExReplace`.
- **Rationale**: Eliminates the overhead of starting a Python interpreter and reduces clipboard locking roundtrips.

### 5. Standardized Testing Infrastructure
- **Decision**: Establish a top-level `tests/` directory and use the `test_<LibName>.ahk` naming convention.
- **Rationale**: Aligns with best practices for modular development and ensures long-term maintainability.

## Risks / Trade-offs

- **[Risk] Shell Overhead (Trigger)** → **Mitigation**: Asynchronous execution in MPV ensures player stability.
- **[Risk] AHK Regex Parity** → **Mitigation**: Verified German hyphenation porting with test cases in `tests/test_ClipboardUtil.ahk`.
- **[Risk] Type Compilation Delay (PowerShell)** → **Mitigation**: Using `Add-Type -AssemblyName` where possible and unique class names for session safety.
