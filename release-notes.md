# Release Notes (v1.48.19)

## Overview
This release adds mouse-based Text-to-Speech triggering to `tts.ahk` and language persistence.

## Script-Specific Updates

### `tts.ahk`
*   **Mouse Trigger**: Added support for triggering TTS by pressing the Middle Mouse Button while selecting text with the Left Mouse Button.
*   **Language Persistence**: The script now remembers the last used language from keyboard shortcuts.
*   **Tray Menu**: Added a dynamic tray menu to show and switch the current TTS language.
*   **Dynamic Tray Icon**: The script now dynamically draws the current language abbreviation (En, Ru, De, Uk) on the tray icon using GDI for instant visual feedback.

**RFC**: [20260119144427-add-tts-mouse-support](docs/rfcs/20260119144427-add-tts-mouse-support.md)

---

# Release Notes (v1.48.18)

## Overview
This release migrates the Text-to-Speech system to a more robust CLI and adds support for the Ukrainian language.

## Script-Specific Updates

### `tts.ahk`
*   **Engine Migration**: Migrated to `anki-tts-cli` for more robust text-to-speech processing.
*   **Added Ukrainian Support**: Introduced `Ctrl+Alt+Shift+5` for Ukrainian language TTS.

**RFC**: [20260119122450-v1-48-18-release](docs/rfcs/20260119122450-v1-48-18-release.md)

---

# Release Notes (v1.48.16)

## Overview
This release resolves the "Token Collision" bug and introduces enterprise-grade debuggability by capturing standard errors during translation. It also consolidates the automated test suite for better reliability.

## Script-Specific Updates

### `translate-selection.ahk`
*   **Feature: Robust Token Strategy**:
    *   **Phase 1: Collision Protection**: Literal occurrences of tokens (`[[S]]`, `[[B]]`, `[[N]]`) are now escaped locally to prevent misinterpretation as functional tokens.
    *   **Logic Refinement**: Improved internal placeholder format (`AHK_ESC_X_`) to ensure zero overlap with restoration patterns.
    *   **Phase 3: DeepL Artifact Handling**: Transitioned to regex-based unescaping to handle minor API-side formatting shifts.
*   **Feature: Enhanced Debuggability**:
    *   **Standard Error Capture**: Now redirects `stderr` to the output log (`2>&1`). If a command fails, the script displays the actual Python error/traceback.
    *   **ExitCode Validation**: Added explicit checking of process exit codes to trigger error reporting.

### `tests/test_integration.ahk`
*   **Consolidated Test Suite**: Replaced individual scripts with a comprehensive integration test covering whitespace, tokens, and collisions in a single pipeline.

**RFC**: [20260118111559-robust-token-collision-protection](docs/rfcs/20260118111559-robust-token-collision-protection.md)

---

# Release Notes (v1.48.14)

## Overview
This release introduces a robust whitespace preservation feature and a new configuration option to control trimming behavior in the translation script.

## Script-Specific Updates

### `translate-selection.ahk`
*   **Feature: Robust Whitespace Preservation**: Implemented a pre-extraction and post-restoration strategy for leading and trailing whitespace. This ensures that accidentally captured spaces, tabs, and newlines are perfectly preserved, regardless of the translation provider's behavior.
*   **Configuration Logic**: Updated to respect the new `TrimWhitespace` setting.

### Configuration (`settings.ini`)
*   **New Option `TrimWhitespace`**:
    *   `TrimWhitespace=false` (Default): Preserves all leading/trailing whitespace from the original selection. Recommended for chat and sentence-boundary translation.
    *   `TrimWhitespace=true`: Trims the translated output of all leading/trailing whitespace (Legacy behavior).

**RFC**: [20260118101956-whitespace-preservation-option](docs/rfcs/20260118101956-whitespace-preservation-option.md)

---

# Release Notes (v1.48.11)

## Overview
Documentation update to include links to published draft scripts and dependencies.

## Documentation
*   Added "Related Repositories" section to `README.md`.
*   Added repository links to `translate-selection.ahk` and `tts.ahk` headers.

**RFC**: [20260113230434-link-published-scripts](docs/rfcs/20260113230434-link-published-scripts.md)

---

# Release Notes (v1.48.10)

## Overview
This release adds a productivity feature for **Google AI Studio**, allowing rapid deletion of chat items using `Alt+Click`.

## Script-Specific Updates

### `hotkeys.ahk`
*   **Feature: Rapid Deletion Hotkey**:
    *   **Action**: `Alt + Left Click` on a menu button (three-dots) automatically opens the menu and clicks "Delete".
    *   **Behavior**:
        *   **Auto-Return**: The cursor immediately snaps back to its original position, preserving mouse context.
        *   **Looping**: Holding the mouse button repeats the action, allowing you to sweep across a list to delete multiple items quickly.

**RFC**: [20251224202917-google-ai-studio-hotkeys](docs/rfcs/20251224202917-google-ai-studio-hotkeys.md)

**Full Changelog**: https://github.com/voothi/20240411110510-autohotkey/compare/v1.48.8...v1.48.10

---

# Release Notes (v1.48.8)

## Overview
This release extends the `hotkeys.ahk` utility to support the **Antigravity** application, providing a more intuitive typing experience in its chat interface.

## Script-Specific Updates

### `hotkeys.ahk`
*   **Feature: Antigravity Support**:
    *   **Enter**: Now acts as "New Line" (sends `Shift+Enter`), matching the behavior in Google AI Studio.
    *   **Ctrl+Enter**: Retains native behavior (Submit/Commit).
    *   **Shift+Enter**: Retains native behavior (New Line).

**RFC**: [20251223110924-antigravity-hotkeys](docs/rfcs/20251223110924-antigravity-hotkeys.md)

**Full Changelog**: https://github.com/voothi/20240411110510-autohotkey/compare/v1.48.4...v1.48.8

---

# Release Notes (v1.44.2 - v1.48.4)

## Overview
This cumulative update brings major improvements to **Security**, **Usability**, and **Translation Accuracy**. It introduces enterprise-grade API key protection, seamless multi-provider cycling, and a robust new tokenization strategy to strictly preserve code structure and indentation.

## Script-Specific Updates

### `translate-selection.ahk` (Main Runtime)
*   **Feature: Strict Indentation Preservation**: Implemented a new tokenization logic (`[[S]]`, `[[B]]`, `[[N]]`) that strictly protects code blocks and whitespace from being mangled or consumed during DeepL translation.
*   **Feature: Multi-Provider Cycling**: Pressing the hotkey (e.g., `Ctrl+Alt+F2`) repeatedly on the same selection now cycles through available providers (Google <-> DeepL).
*   **Feature: Smart Context**: The script now persists session state to enable provider switching without needing to re-copy the source text.
*   **Configuration Logic**: Updated to respect the `UseTokens` setting from `settings.ini`, allowing users to toggle the advanced whitespace protection on/off.

### `setup-security.ahk` (New Utility)
*   **New Script**: A dedicated setup utility introduced in v1.44.2.
*   **Functionality**: securely encrypts API keys and stores them in an obfuscated format (`secrets.ini`). This ensures that plain-text API keys are never stored on disk, only decrypted in memory during runtime.

### `settings.ini` & Templates
*   **New Section `[Settings]`**: Added to control global behavior.
*   **New Option `UseTokens`**:
    *   `UseTokens=true`: Enables the advanced token strategy (`[[S]]`, `[[B]]`, `[[N]]`) for strict preservation of indentation and backslashes (Recommended for code).
    *   `UseTokens=false` (Default): Uses standard behavior (flattening newlines) for general text stability.
*   **Path Handling**: Improved support for system environment variables (e.g., `%USERPROFILE%`) in path configurations.

## How to Update
1. **Update Scripts**: Replace `translate-selection.ahk` and ensure `setup-security.ahk` is present.
2. **Setup Security**: Run `setup-security.ahk` to encrypt your DeepL API key if you haven't already.
3. **Configure**: Update `settings.ini` to enable tokens if desired:
   ```ini
   [Settings]
   UseTokens=true
   ```

**Full Changelog**: https://github.com/voothi/20240411110510-autohotkey/compare/v1.44.2...v1.48.4
