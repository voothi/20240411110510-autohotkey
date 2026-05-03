## ADDED Requirements

### Requirement: Layout-Agnostic Change Notification
The bridge SHALL utilize a layout-independent notification mechanism (e.g., Virtual Key signals) to ensure the observer (AHK) is triggered reliably across different system keyboard layouts (EN/RU).

#### Scenario: Triggering in non-Latin layout
- **WHEN** the system is set to Russian layout
- **THEN** the bridge SHALL successfully signal the dictionary tool without being intercepted by layout translation layers

### Requirement: Optimized Text Normalization
The bridge SHALL perform text cleaning (newline removal and German hyphen joining) using high-performance internal logic (e.g., AHK RegExReplace) to ensure zero-latency preparation for the dictionary lookup.

#### Scenario: Snap-to-popup performance
- **WHEN** text is signaled as ready from the host application
- **THEN** the bridge SHALL normalize the text and present it to GoldenDict in <20ms
