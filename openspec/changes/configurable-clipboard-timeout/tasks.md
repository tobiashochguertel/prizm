## 1. Add clipboard timeout setting

- [ ] 1.1 Add `clipboardClearSeconds` property to a settings model (or `UserDefaults` key `clipboardClearSeconds`, default 30, clamped 10–300)
- [ ] 1.2 Add a "Security" section to `SettingsView` with a "Clear clipboard after" row (stepper showing seconds, or a picker with preset values: 10s, 20s, 30s, 45s, 60s, 90s, 120s, 300s)

## 2. Replace hardcoded timeout in copy paths

- [ ] 2.1 In `VaultBrowserViewModel.copy()`, replace `Task.sleep(for: .seconds(30))` with a value read from the setting
- [ ] 2.2 In `PasswordGeneratorViewModel.copyToClipboard()`, same change
- [ ] 2.3 Extract the clipboard copy + auto-clear logic into a shared helper to eliminate duplication (three similar call sites: vault copy, password generator copy — meets the §VI threshold of three)

## 3. Update existing spec

- [ ] 3.1 Update `openspec/specs/copy-menu-commands/spec.md` to replace "30-second auto-clear" with "configurable auto-clear (default 30s)"

## 4. Tests

- [ ] 4.1 Test: default timeout is 30 seconds when setting is unset
- [ ] 4.2 Test: timeout is clamped to 10–300 seconds
- [ ] 4.3 Test: timeout persists in `UserDefaults` across instances
- [ ] 4.4 Test: both `VaultBrowserViewModel.copy()` and `PasswordGeneratorViewModel.copyToClipboard()` use the configured value
- [ ] 4.5 Test: new copy cancels and restarts the clear timer
