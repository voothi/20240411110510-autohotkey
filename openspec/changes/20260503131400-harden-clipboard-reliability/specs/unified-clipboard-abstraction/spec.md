## MODIFIED Requirements

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
