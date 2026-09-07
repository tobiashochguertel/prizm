## ADDED Requirements

### Requirement: Configurable clipboard auto-clear timeout
The system SHALL provide a user-configurable setting controlling how long copied secrets remain on the clipboard before automatic clearing. The setting SHALL default to 30 seconds and SHALL be adjustable between 10 and 300 seconds (5 minutes). The setting SHALL persist across app launches via `UserDefaults`. Both the vault field copy action and the password generator copy action SHALL use this setting instead of a hardcoded duration.

#### Scenario: Default timeout is 30 seconds
- **GIVEN** the user has never changed the clipboard timeout setting
- **WHEN** the user copies a secret to the clipboard
- **THEN** the clipboard SHALL be cleared after 30 seconds

#### Scenario: User changes timeout to 60 seconds
- **GIVEN** the user is on the Settings screen
- **WHEN** the user changes "Clear clipboard after" to 60 seconds
- **AND** the user copies a secret to the clipboard
- **THEN** the clipboard SHALL be cleared after 60 seconds

#### Scenario: Minimum timeout is 10 seconds
- **GIVEN** the user is on the Settings screen
- **WHEN** the user attempts to set the timeout below 10 seconds
- **THEN** the setting SHALL be clamped to 10 seconds

#### Scenario: Maximum timeout is 300 seconds
- **GIVEN** the user is on the Settings screen
- **WHEN** the user attempts to set the timeout above 300 seconds
- **THEN** the setting SHALL be clamped to 300 seconds

#### Scenario: Timeout persists across app launches
- **GIVEN** the user has set the timeout to 120 seconds
- **WHEN** the user quits and relaunches the app
- **THEN** the timeout SHALL remain 120 seconds

#### Scenario: Password generator uses the same timeout
- **GIVEN** the user has set the clipboard timeout to 45 seconds
- **WHEN** the user copies a generated password from the password generator
- **THEN** the clipboard SHALL be cleared after 45 seconds

#### Scenario: New copy resets the clear timer
- **GIVEN** the user copied a secret 10 seconds ago with a 30-second timeout
- **WHEN** the user copies a different secret
- **THEN** the clear timer SHALL restart from the beginning for the new value
- **AND** the previous value SHALL NOT be cleared separately
