## Purpose
Provides a unified, layout-independent clipboard and selection copy trigger engine.
## Requirements
### Requirement: Layout-Independent Trigger Engine
The `set_clipboard(text, mode)` function SHALL explicitly notify the dictionary tool using a layout-independent mechanism (e.g., Virtual Key signals) to ensure reliable operation across EN/RU keyboard layouts.

#### Scenario: Multi-layout dictionary trigger
- **WHEN** the user triggers a dictionary lookup in any keyboard layout
- **THEN** the system SHALL send the raw VK signal for the configured hotkey without typing character-specific "ghost" letters

### Requirement: Unified Multi-Mode Configuration
The system SHALL expose a consistent naming standard (`gd_` prefix) for all dictionary-related settings, supporting independent notification paths for "Popup" and "Main Window" modes.

#### Scenario: Mode-specific hotkey triggering
- **WHEN** `gd_hotkey_popup` or `gd_hotkey_main` are signaled
- **THEN** the system SHALL dispatch the correct notification signal based on the intended window target

### Requirement: Modifier-Safe Selection Capture
The selection capture mechanism SHALL halt execution and wait for all physically held modifier keys (`Ctrl`, `Alt`, `Shift`, `Win`) to be released before simulating copy keypresses (`Ctrl+C`) to prevent race conditions and hotkey collisions.

#### Scenario: Physical modifier keys held down
- **WHEN** the user triggers a selection copy while physically holding modifier keys
- **THEN** the copy mechanism SHALL pause until all modifier keys are physically released before sending simulated key signals

