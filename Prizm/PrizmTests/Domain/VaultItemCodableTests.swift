import XCTest
@testable import Prizm

/// Unit tests for VaultItem Codable conformance — JSON round-trip for all item types.
@MainActor
final class VaultItemCodableTests: XCTestCase {

    // MARK: - Helpers

    private func roundTrip(_ item: VaultItem) throws -> VaultItem {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(VaultItem.self, from: data)
    }

    // MARK: - Login

    func testLoginItemRoundTrip() throws {
        let item = VaultItem(
            id: "abc-123",
            name: "GitHub",
            isFavorite: true,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_100),
            content: .login(LoginContent(
                username: "user@example.com",
                password: "s3cret",
                uris: [LoginURI(uri: "https://github.com", matchType: .domain)],
                totp: nil,
                notes: "My account",
                customFields: []
            )),
            folderId: "folder-1",
            organizationId: nil,
            collectionIds: []
        )
        let decoded = try roundTrip(item)
        XCTAssertEqual(decoded, item)
    }

    // MARK: - Card

    func testCardItemRoundTrip() throws {
        let item = VaultItem(
            id: "card-1",
            name: "Visa",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .card(CardContent(
                cardholderName: "John Doe",
                brand: "Visa",
                number: "4111111111111111",
                expMonth: "12",
                expYear: "2030",
                code: "123",
                notes: nil,
                customFields: []
            ))
        )
        let decoded = try roundTrip(item)
        XCTAssertEqual(decoded, item)
    }

    // MARK: - Identity

    func testIdentityItemRoundTrip() throws {
        let item = VaultItem(
            id: "id-1",
            name: "Personal ID",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .identity(IdentityContent(
                title: "Mr",
                firstName: "John",
                middleName: nil,
                lastName: "Doe",
                address1: "123 Main St",
                address2: nil,
                address3: nil,
                city: "Anytown",
                state: "CA",
                postalCode: "12345",
                country: "USA",
                company: "Acme",
                email: "john@example.com",
                phone: "+1-555-1234",
                ssn: nil,
                username: "jdoe",
                passportNumber: nil,
                licenseNumber: nil,
                notes: nil,
                customFields: []
            ))
        )
        let decoded = try roundTrip(item)
        XCTAssertEqual(decoded, item)
    }

    // MARK: - Secure Note

    func testSecureNoteItemRoundTrip() throws {
        let item = VaultItem(
            id: "note-1",
            name: "My Note",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .secureNote(SecureNoteContent(
                notes: "Secret note content",
                customFields: []
            ))
        )
        let decoded = try roundTrip(item)
        XCTAssertEqual(decoded, item)
    }

    // MARK: - SSH Key

    func testSSHKeyItemRoundTrip() throws {
        let item = VaultItem(
            id: "ssh-1",
            name: "My SSH Key",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .sshKey(SSHKeyContent(
                privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----\n...",
                publicKey: "ssh-ed25519 AAAA...",
                keyFingerprint: "SHA256:abc123",
                notes: nil,
                customFields: []
            ))
        )
        let decoded = try roundTrip(item)
        XCTAssertEqual(decoded, item)
    }

    // MARK: - ItemContent type discrimination

    func testItemContentEncodesWithTypeKey() throws {
        let content = ItemContent.card(CardContent(
            cardholderName: "John",
            brand: nil,
            number: nil,
            expMonth: nil,
            expYear: nil,
            code: nil,
            notes: nil,
            customFields: []
        ))
        let encoder = JSONEncoder()
        let data = try encoder.encode(content)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["type"] as? String, "card")
    }

    func testItemContentDecodesFromTypeKey() throws {
        let json = """
        {"type": "login", "login": {"username": "u", "password": "p", "uris": [], "totp": null, "notes": null, "customFields": []}}
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let content = try decoder.decode(ItemContent.self, from: data)
        guard case .login(let login) = content else {
            XCTFail("Expected .login, got \(content)")
            return
        }
        XCTAssertEqual(login.username, "u")
        XCTAssertEqual(login.password, "p")
    }

    func testItemContentRejectsUnknownType() {
        let json = """
        {"type": "unknown", "unknown": {}}
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(ItemContent.self, from: data))
    }

    // MARK: - Date encoding

    func testDatesAreISO8601() throws {
        let item = VaultItem(
            id: "date-1",
            name: "Test",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .secureNote(SecureNoteContent(notes: nil, customFields: []))
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("2023-11-14"), "Expected ISO 8601 date in JSON: \(json)")
    }

    // MARK: - toJSONString

    func testToJSONStringReturnsValidJSON() {
        let item = VaultItem(
            id: "json-1",
            name: "Test",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .secureNote(SecureNoteContent(notes: "hello", customFields: []))
        )
        let json = item.toJSONString()
        XCTAssertNotNil(json)
        XCTAssertTrue(json!.contains("\"id\" : \"json-1\""))
    }

    // MARK: - Custom fields

    func testCustomFieldRoundTrip() throws {
        let item = VaultItem(
            id: "cf-1",
            name: "Test",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .login(LoginContent(
                username: nil,
                password: nil,
                uris: [],
                totp: nil,
                notes: nil,
                customFields: [
                    CustomField(name: "PIN", value: "1234", type: .hidden, linkedId: nil),
                    CustomField(name: "Active", value: "true", type: .boolean, linkedId: nil)
                ]
            ))
        )
        let decoded = try roundTrip(item)
        XCTAssertEqual(decoded, item)
    }

    // MARK: - Attachments

    func testAttachmentRoundTrip() throws {
        let item = VaultItem(
            id: "att-1",
            name: "Test",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .secureNote(SecureNoteContent(notes: nil, customFields: [])),
            attachments: [
                Attachment(id: "a1", fileName: "doc.pdf", encryptedKey: "2.abc|def|ghi",
                          size: 1024, sizeName: "1 KB", url: "https://example.com/dl",
                          isUploadIncomplete: false)
            ]
        )
        let decoded = try roundTrip(item)
        XCTAssertEqual(decoded, item)
    }
}
