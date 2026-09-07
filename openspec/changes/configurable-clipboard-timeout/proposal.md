## Why

The Constitution (§III) requires that clipboard writes containing secrets "MUST auto-clear after ≤30 seconds (configurable)" and that sensitive data shown in the UI "MUST auto-clear after a configurable timeout." The current implementation hardcodes `30` seconds as a literal in two places — `VaultBrowserViewModel.copy()` and `PasswordGeneratorViewModel.copyToClipboard()` — with no setting exposed to the user and no shared constant. This is a Constitution violation: the timeout is not configurable.

## What Changes

- Add a `clipboardClearSeconds` setting persisted in `UserDefaults` (default: 30, range: 10–300)
- Add a Settings UI row under a new "Security" section: "Clear clipboard after" with a stepper or picker
- Extract the hardcoded `30` into a shared value read from the setting, used by both `VaultBrowserViewModel.copy()` and `PasswordGeneratorViewModel.copyToClipboard()`
- Update the `copy-menu-commands` spec to reference the configurable timeout instead of the hardcoded 30s

## Capabilities

### New Capabilities

- `clipboard-auto-clear`: configurable clipboard auto-clear timeout with Settings UI

### Modified Capabilities

- `copy-menu-commands`: timeout is now configurable (default 30s) instead of hardcoded 30s

## Impact

- `Prizm/Presentation/Settings/SettingsView.swift` — add "Clear clipboard after" row in a new Security section
- `Prizm/Presentation/Vault/VaultBrowserViewModel.swift` — read timeout from UserDefaults instead of hardcoded `30`
- `Prizm/Presentation/Vault/Edit/PasswordGeneratorViewModel.swift` — same change
- `Prizm/PrizmTests/Presentation/VaultBrowserViewModelTests.swift` — update tests that assert 30s to use the configurable value
- `Prizm/PrizmTests/Presentation/PasswordGeneratorViewModelTests.swift` — same
- `openspec/specs/copy-menu-commands/spec.md` — update "30-second auto-clear" to "configurable auto-clear (default 30s)"
