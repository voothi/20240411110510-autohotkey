## ADDED Requirements

### Requirement: Robust Clipboard Change Detection
The AHK bridge SHALL wait up to 3 seconds for clipboard changes to accommodate background utility startup latency (e.g., PowerShell).

#### Scenario: Delayed clipboard update from MPV
- **WHEN** the user triggers a copy operation in MPV that uses a high-latency backend
- **THEN** the AHK script SHALL successfully detect the new data without timing out after 1 second

### Requirement: In-Process Text Normalization
The AHK bridge SHALL perform text cleaning (newline removal and hyphen joining) using internal logic instead of external subprocesses to reduce clipboard locking frequency.

#### Scenario: Immediate lookup after copy
- **WHEN** text is copied to the clipboard
- **THEN** the AHK script SHALL normalize the text and trigger GoldenDict within 50ms of detection
