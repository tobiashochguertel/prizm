## Why

The item list context menu currently offers only Favorite/Unfavorite and Delete. For integration with external tools — such as piping a vault item's JSON to `vault-item-to-print` for PDF generation, or using the item ID in scripts and API calls — users need a quick way to copy the item's UUID and its full JSON representation from the context menu without navigating to a terminal or the Bitwarden web vault.

## What Changes

- Add "Copy Item ID" to the item list context menu — copies the UUID string (no auto-clear; it is not a secret)
- Add "Copy as JSON" to the item list context menu — copies a JSON representation of the decrypted `VaultItem` to the clipboard (with clipboard auto-clear, since the JSON may contain secrets)
- The JSON output SHALL be the decrypted domain model (`VaultItem`), not the encrypted wire format (`RawCipher`). This makes it directly usable by tools like `vault-item-to-print` which expect decrypted JSON in the Bitwarden/1Password item format.
- Add `Codable` conformance to `VaultItem` and its content types (`LoginContent`, `CardContent`, `IdentityContent`, `SecureNoteContent`, `SSHKeyContent`, `LoginURI`, `CustomField`, `Attachment`) so they can be serialized to JSON
- Both context menu items SHALL be available for all item types (Login, SecureNote, Card, Identity, SSHKey), not just Login
- Both items SHALL also appear in the Trash context menu (items in trash still have IDs and JSON)

## Capabilities

### New Capabilities

- `copy-item-json-uuid`: Copy Item ID and Copy as JSON context menu actions on vault items

### Modified Capabilities

- `vault-browser-ui`: item list context menu gains Copy Item ID and Copy as JSON actions
- `vault-item-restore` (trash): trash context menu gains Copy Item ID and Copy as JSON actions

## Impact

- `Prizm/Domain/Entities/VaultItem.swift` — add `Codable` conformance to `VaultItem`, `ItemContent`, and all content structs
- `Prizm/Domain/Entities/CustomField.swift` — add `Codable` conformance if not already present
- `Prizm/Domain/Entities/Attachment.swift` — add `Codable` conformance if not already present
- `Prizm/Presentation/Vault/ItemList/ItemListView.swift` — add Copy Item ID and Copy as JSON to context menu
- `Prizm/Presentation/Vault/Trash/TrashView.swift` — same for trash context menu
- `Prizm/Presentation/Vault/VaultBrowserViewModel.swift` — add `copyItemID(_:)` and `copyItemJSON(_:)` methods
- `Prizm/Presentation/AccessibilityIdentifiers.swift` — add accessibility identifiers for new menu items
- `Prizm/PrizmTests/Domain/` — tests for VaultItem JSON encoding round-trip
- `Prizm/PrizmTests/Presentation/` — tests for context menu actions
- `Prizm/UITests/` — UI test for Copy Item ID and Copy as JSON from context menu
