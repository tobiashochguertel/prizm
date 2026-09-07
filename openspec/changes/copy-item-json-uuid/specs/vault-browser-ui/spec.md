## ADDED Requirements

### Requirement: Copy Item ID from context menu
The system SHALL provide a "Copy Item ID" action in the vault item list context menu and the Trash context menu. The action SHALL copy the item's UUID string to the clipboard without auto-clear, since the UUID is not a secret. The action SHALL be available for all item types.

#### Scenario: Copy Item ID from item list
- **GIVEN** an item exists in the vault list
- **WHEN** the user right-clicks the item and selects "Copy Item ID"
- **THEN** the item's UUID SHALL be copied to the clipboard as a plain string
- **AND** the clipboard SHALL NOT be auto-cleared (the UUID is not a secret)

#### Scenario: Copy Item ID from Trash
- **GIVEN** an item exists in the Trash
- **WHEN** the user right-clicks the item and selects "Copy Item ID"
- **THEN** the item's UUID SHALL be copied to the clipboard as a plain string

#### Scenario: Copy Item ID works for all item types
- **GIVEN** items of type Login, SecureNote, Card, Identity, and SSHKey exist
- **WHEN** the user right-clicks any item and selects "Copy Item ID"
- **THEN** the item's UUID SHALL be copied to the clipboard

#### Scenario: Copy Item ID confirmation feedback
- **GIVEN** the user selects "Copy Item ID" from the context menu
- **WHEN** the UUID is copied to the clipboard
- **THEN** the system SHALL provide brief visual feedback (e.g. the menu closes, or a transient toast)

---

### Requirement: Copy as JSON from context menu
The system SHALL provide a "Copy as JSON" action in the vault item list context menu and the Trash context menu. The action SHALL serialize the decrypted `VaultItem` domain model to a JSON string and copy it to the clipboard with auto-clear (default 30 seconds, configurable per the `clipboard-auto-clear` spec). The JSON SHALL include all item fields: id, name, type, content (login/card/identity/secureNote/sshKey), custom fields, attachments metadata, folderId, organizationId, collectionIds, favorite, deleted, creationDate, revisionDate, and reprompt. The JSON SHALL NOT include encrypted EncString values — only decrypted plaintext. The action SHALL be available for all item types.

#### Scenario: Copy as JSON from item list
- **GIVEN** a Login item with username, password, URIs, and custom fields is selected
- **WHEN** the user right-clicks the item and selects "Copy as JSON"
- **THEN** a JSON string representing the decrypted `VaultItem` SHALL be copied to the clipboard
- **AND** the clipboard SHALL be auto-cleared after the configured timeout (default 30s)
- **AND** the JSON SHALL contain plaintext values, not EncString-encoded values

#### Scenario: Copy as JSON from Trash
- **GIVEN** an item exists in the Trash
- **WHEN** the user right-clicks the item and selects "Copy as JSON"
- **THEN** the decrypted JSON SHALL be copied to the clipboard with auto-clear

#### Scenario: Copy as JSON works for all item types
- **GIVEN** items of type Login, SecureNote, Card, Identity, and SSHKey exist
- **WHEN** the user right-clicks any item and selects "Copy as JSON"
- **THEN** the JSON SHALL contain the type-specific content fields for that item type

#### Scenario: JSON round-trips through Codable
- **GIVEN** a `VaultItem` with all fields populated
- **WHEN** the item is encoded to JSON and decoded back
- **THEN** the decoded `VaultItem` SHALL be equal to the original

#### Scenario: JSON is valid for external tool consumption
- **GIVEN** a Login item has been copied as JSON to the clipboard
- **WHEN** the JSON is piped to an external tool (e.g. `vault-item-to-print`)
- **THEN** the JSON SHALL be a single valid JSON object that can be parsed by a standard JSON parser

#### Scenario: Copy as JSON auto-clears the clipboard
- **GIVEN** the user copies an item as JSON
- **WHEN** the configured clipboard timeout elapses (default 30 seconds)
- **THEN** the clipboard SHALL be cleared

---

### Requirement: VaultItem is Codable
The `VaultItem` domain entity and all its associated types (`ItemContent`, `LoginContent`, `LoginURI`, `CardContent`, `IdentityContent`, `SecureNoteContent`, `SSHKeyContent`, `CustomField`, `Attachment`) SHALL conform to `Codable` so they can be serialized to and deserialized from JSON. The `ItemContent` enum SHALL use a discriminated union encoding with a "type" key to distinguish Login, SecureNote, Card, Identity, and SSHKey.

#### Scenario: VaultItem encodes to JSON
- **GIVEN** a `VaultItem` with content `.login(LoginContent(...))`
- **WHEN** the item is encoded with `JSONEncoder`
- **THEN** the output SHALL be a valid JSON object with all fields present

#### Scenario: ItemContent discriminates by type
- **GIVEN** a `VaultItem` with content `.card(CardContent(...))`
- **WHEN** the item is encoded to JSON
- **THEN** the JSON SHALL contain a "content" key with a "type" field set to "card"
- **AND** the content object SHALL contain card-specific fields (cardholderName, brand, number, etc.)

#### Scenario: VaultItem decodes from JSON
- **GIVEN** a JSON string produced by encoding a `VaultItem`
- **WHEN** the JSON is decoded with `JSONDecoder`
- **THEN** the result SHALL be a `VaultItem` equal to the original

#### Scenario: Date encoding uses ISO 8601
- **GIVEN** a `VaultItem` with `creationDate` and `revisionDate`
- **WHEN** the item is encoded to JSON
- **THEN** the date fields SHALL be formatted as ISO 8601 strings
