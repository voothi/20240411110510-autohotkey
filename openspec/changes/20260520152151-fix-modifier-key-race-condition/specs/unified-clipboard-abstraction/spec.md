## ADDED Requirements

### Requirement: Modifier-Safe Selection Capture
The selection capture mechanism SHALL halt execution and wait for all physically held modifier keys (`Ctrl`, `Alt`, `Shift`, `Win`) to be released before simulating copy keypresses (`Ctrl+C`) to prevent race conditions and hotkey collisions.

#### Scenario: Physical modifier keys held down
- **WHEN** the user triggers a selection copy while physically holding modifier keys
- **THEN** the copy mechanism SHALL pause until all modifier keys are physically released before sending simulated key signals
