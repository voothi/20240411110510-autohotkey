## Context

AutoHotkey's automated logical modifier state restoration sequence (`Alt` up, `Shift` up, send `^c`, `Alt` down, `Shift` down) to send exact keystrokes like `Ctrl+C` while complex modifier hotkeys (such as `Ctrl+Alt+Shift+1`) are physically held creates timing race conditions. The active OS registers `c` before simulated modifier releases are fully queued, triggering undesired application hotkeys (like opening Chrome DevTools `Ctrl+Shift+C`).

## Goals / Non-Goals

**Goals:**
- Implement a physical key waiting utility in `Lib\ClipboardUtil.ahk` to serialize simulated copy keystrokes only after the physical keys have been released.
- Refactor the main lookup hotkeys `gd-main.ahk` (`^!+1`) and `gd-side.ahk` (`^!+q`) to use the unified `SmartCopy` abstraction.
- Resolve AutoHotkey case-insensitivity variable shadowing runtime issues.

**Non-Goals:**
- Adding auto-reload checks.
- Refactoring unrelated hotkeys not using complex modifier layouts.

## Decisions

### Decision 1: Physical state key querying via GetKeyState("P") + KeyWait
- **Choice**: Physical key check (`"P"` parameter) followed by `KeyWait`.
- **Alternatives Considered**: 
  - *Logical key checks*: Discarded because AHK's own simulated state adjustments interfere with logical checks.
  - *Explicit `Send {Key Up}` releases*: Discarded because manually sending key releases still risks race conditions with active physical hardware holds.
- **Rationale**: Physical querying ensures we block specifically and only when the user's fingers are physically pressing the keys, completely bypassing restoration timing loops.

### Decision 2: Abstraction inside `SmartCopy`
- **Choice**: Calling the wait sequence inside `SmartCopy(timeout, shouldWait)` default loop.
- **Alternatives Considered**:
  - *Direct calls inside gd-main / gd-side hotkeys*: Discarded because it repeats boilerplate logic in every hotkey scope.
- **Rationale**: Centralizing the protection in `SmartCopy` hardens all current and future selection-copy functions automatically.

### Decision 3: Renaming parameter `waitForModifiers` to `shouldWait`
- **Choice**: Renaming the function parameter.
- **Rationale**: Since AutoHotkey is case-insensitive, the function parameter `waitForModifiers` conflicted with the global function `WaitForModifiers()`, causing a runtime `Integer call` crash. Renaming to `shouldWait` solves the issue.

## Risks / Trade-offs

- **[Risk] → Mitigation**: The hotkey may feel slightly laggy if the user physically holds down the keys for an extended duration. → **Mitigation**: Since the check only queries keys physically down, it triggers instantly if released normally, and guarantees absolute safety.
