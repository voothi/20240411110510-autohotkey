## ADDED Requirements

### Requirement: Standardized Test Directory
The project SHALL maintain a dedicated `tests/` directory at the repository root for all automated and semi-automated verification scripts.

#### Scenario: Location of new library tests
- **WHEN** a developer creates a new verification script for a library component
- **THEN** the script SHALL be placed in the `tests/` folder to ensure visibility and separation from production code

### Requirement: Test Naming Convention
Verification scripts SHALL follow the naming pattern `test_<ComponentName>.ahk` to ensure consistency with existing test suites and facilitate discovery.

#### Scenario: Naming a test for ClipboardUtil
- **WHEN** naming a test for `ClipboardUtil.ahk`
- **THEN** the file name SHALL be `test_ClipboardUtil.ahk`
