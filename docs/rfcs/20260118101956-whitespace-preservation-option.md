# RFC: 20260118101956 - Whitespace Preservation Option for translate-selection.ahk

## Overview
Add an option to toggle leading and trailing whitespace trimming in the translation script. This prevents the loss of accidentally captured spaces or specific formatting (like newlines) during the translation process.

## Problem Statement
Previously, the script automatically trimmed all leading and trailing whitespace from the translated output. While this cleaned up some CLI noise, it caused issues for users translating parts of sentences or working in chat interfaces where trailing spaces are significant for sentence separation. Accidental capture of a space would result in it being deleted, requiring manual restoration.

## Implementation Details

### Analytics and Decisions
- **Decision: External Extraction**: Instead of relying on the translation provider (Google/DeepL) to preserve whitespace, the script now extracts leading and trailing whitespace (including tabs and newlines) *before* any processing occurs.
- **Decision: Settings-Driven**: A new `TrimWhitespace` option in `settings.ini` controls this behavior.
  - `false` (Default): Extracts and re-attaches whitespace exactly as it was in the selection.
  - `true`: Explicitly trims the output (legacy behavior).
- **Decision: Efficiency**: If the selection consists only of whitespace, the script returns immediately, avoiding unnecessary API calls.
- **Logic Robustness**: By "parking" the whitespace in variables and only translating the "Core Text", we improve translation quality (cleaner input) and ensure 100% accuracy in whitespace restoration regardless of the provider's behavior.

## Proposed Changes

### Configuration
- `settings.ini`: Added `TrimWhitespace=false` under `[Settings]`.
- `settings.ini.template`: Added option and detailed documentation in comments.

### AutoHotkey Script
- Modified `translate-selection.ahk` to:
  1. Read `TrimWhitespace`.
  2. Perform pre-translation extraction of `LeadingWS` and `TrailingWS`.
  3. Perform post-translation restoration of the "parked" whitespace.

## Verification Result
Manual verification confirmed that selecting `"word "` (with a trailing space) results in the space being preserved in the translation. The automated `test_whitespace.ahk` (used during development) verified edge cases like pure whitespace and mixed newlines.
