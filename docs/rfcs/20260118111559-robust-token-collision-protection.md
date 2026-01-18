# RFC: 20260118111559 - Robust Token Collision Protection for translate-selection.ahk

## Overview
Implement a multi-phase pre/post-processing strategy to protect literal occurrences of internal functional tokens (e.g., `[[S]]`, `[[B]]`, `[[N]]`) during translation. This prevents "Token Collision" bugs where documentation text matching these patterns is incorrectly mutated.

## Problem Statement
The script uses specific tokens (`[[S]]`, `[[B]]`, `[[N]]`) to preserve indentation, backslashes, and newlines. However, if these exact strings appear in the *original* text (e.g., in a wikilink or documentation about the script), the restoration logic misinterprets them as functional tokens, leading to corrupted output or deletion of the literal text.

## Implementation Details

### Analytics and Decisions
1.  **Decision: Multi-Phase Protection**: Instead of choosing different tokens (which might also eventually collide), we implement an **Escaping Layer**.
    - **Phase 1 (Escape)**: Detect literal `[[S]]` etc. and replace them with `AHK_ESC_S_`.
    - **Phase 2 (Tokenize)**: Proceed with standard functional replacement (e.g., "  " -> `[[S]]`).
    - **Phase 3 (Restore & Unescape)**: Functional tokens are restored first, then the `AHK_ESC_` placeholders are restored to their literal brackets.
2.  **Decision: Bracket-Free Placeholder**: The internal escape placeholder must *not* contain brackets (e.g., `AHK_ESC_S_` instead of `AHK_ESC_[[S]]`). This ensures the functional restoration regex (which looks for `[[...]]`) does not match the escaped content.
3.  **Decision: Regex Robustness**: Unescaping uses regex (e.g., `i)AHK_ESC_S_`) to remain resilient against minor whitespace or capitalization shifts that some translation providers might introduce.
4.  **Decision: Standard Error Capture**: Combined with this change, the command execution logic now redirects standard error (`2>&1`) to the output file to capture Python-level failures for better debugging.

## Proposed Changes

### `translate-selection/translate-selection.ahk`
- Updated `TranslateSelection` function with the 3-phase processing logic.
- Updated `GetGoogleCommand` and `GetDeepLCommand` to use stdout/stderr redirection.
- Added ExitCode verification and error reporting log display.

### `translate-selection/tests/test_integration.ahk`
- Created a consolidated test suite that verifies boundary whitespace, token logic, and literal collision protection in a single integrated pipeline.

## Verification Result
Manual testing with the user's specific "Wikilink + Code" example (`Проверьте [[S]]...`) confirmed 100% accuracy. The automated `test_integration.ahk` covers 7 critical scenarios, including DeepL artifacts and mixed functional/literal content, all of which pass successfully.

---
**Request ZID**: 20260118111559
