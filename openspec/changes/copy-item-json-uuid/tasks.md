## 1. Add Codable conformance to domain entities

- [ ] 1.1 Add `Codable` conformance to `VaultItem` — all stored properties are already `Codable`-compatible (String, Bool, Date, arrays); add conformance declaration
- [ ] 1.2 Add `Codable` conformance to `ItemContent` — implement custom `encode(to:)` and `init(from:)` using a discriminated union with a `"type"` key (`"login"`, `"secureNote"`, `"card"`, `"identity"`, `"sshKey"`)
- [ ] 1.3 Add `Codable` conformance to `LoginContent`, `LoginURI`, `CardContent`, `IdentityContent`, `SecureNoteContent`, `SSHKeyContent` — all stored properties are simple types; add conformance declarations
- [ ] 1.4 Add `Codable` conformance to `CustomField` if not already present
- [ ] 1.5 Add `Codable` conformance to `Attachment` if not already present
- [ ] 1.6 Configure `JSONEncoder.dateEncodingStrategy = .iso8601` and `JSONDecoder.dateDecodingStrategy = .iso8601` in the JSON serialization helper

## 2. Add JSON serialization helper

- [ ] 2.1 Add a `VaultItemJSONEncoder` (or extension on `VaultItem`) that encodes to a pretty-printed JSON string using `.iso8601` date strategy
- [ ] 2.2 Handle encoding errors gracefully — log via `os.Logger` and surface a user-visible error if encoding fails

## 3. Add context menu actions to item list

- [ ] 3.1 Add `onCopyItemID: ((String) -> Void)?` and `onCopyItemJSON: ((VaultItem) -> Void)?` callbacks to `ItemListView`
- [ ] 3.2 Add "Copy Item ID" and "Copy as JSON" buttons to the context menu in `ItemListView`, after Favorite/Unfavorite and before Delete, separated by a `Divider`
- [ ] 3.3 Add accessibility identifiers: `AccessibilityID.ItemList.copyItemID` and `AccessibilityID.ItemList.copyItemJSON`

## 4. Add context menu actions to Trash

- [ ] 4.1 Add `onCopyItemID` and `onCopyItemJSON` callbacks to `TrashView`
- [ ] 4.2 Add "Copy Item ID" and "Copy as JSON" buttons to the Trash context menu, after Restore and before Delete Permanently, separated by a `Divider`
- [ ] 4.3 Add accessibility identifiers for the trash context menu items

## 5. Wire up copy logic in ViewModel

- [ ] 5.1 Add `copyItemID(_ id: String)` to `VaultBrowserViewModel` — copies UUID to `NSPasteboard` without auto-clear
- [ ] 5.2 Add `copyItemJSON(_ item: VaultItem)` to `VaultBrowserViewModel` — serializes to JSON via the helper, copies to `NSPasteboard` with auto-clear
- [ ] 5.3 Wire the callbacks from `ItemListView` and `TrashView` to the ViewModel methods via `VaultBrowserView`

## 6. Tests

- [ ] 6.1 Unit test: `VaultItem` JSON round-trip (encode → decode → equality check) for each item type
- [ ] 6.2 Unit test: `ItemContent` discriminated union encoding produces correct "type" key for each case
- [ ] 6.3 Unit test: date fields are ISO 8601 formatted in JSON output
- [ ] 6.4 Unit test: `copyItemID` copies the UUID string to pasteboard without scheduling auto-clear
- [ ] 6.5 Unit test: `copyItemJSON` copies a valid JSON string to pasteboard with auto-clear scheduled
- [ ] 6.6 UI test: right-click an item → "Copy Item ID" appears in context menu → clipboard contains the UUID
- [ ] 6.7 UI test: right-click an item → "Copy as JSON" appears in context menu → clipboard contains valid JSON
- [ ] 6.8 UI test: both actions appear in Trash context menu
