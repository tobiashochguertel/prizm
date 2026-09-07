import Foundation

/// A fully-decrypted vault entry. Produced by `CipherMapper` from a `RawCipher`.
/// Value type — safe to pass across layers without defensive copying.
nonisolated struct VaultItem: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let folderId: String?
    let name: String
    let isFavorite: Bool
    let isDeleted: Bool
    let creationDate: Date
    let revisionDate: Date
    let content: ItemContent
    /// Master-password re-prompt setting mirrored from the Bitwarden wire format.
    /// 0 = disabled (default), 1 = require master password before revealing fields.
    /// Stored here so `CipherMapper.toRawCipher` can round-trip it unchanged on PUT,
    /// preventing silent loss of re-prompt protection during edits.
    let reprompt: Int
    /// File attachments belonging to this vault item.
    /// Empty (`[]`) when the server returns no attachments or an explicit `null`.
    let attachments: [Attachment]
    /// Non-nil when this item belongs to a Bitwarden organization.
    /// Nil for personal vault items.
    let organizationId: String?
    /// The collections this item is assigned to within its organization.
    /// Empty (`[]`) for personal items and org items not assigned to any collection.
    let collectionIds: [String]

    /// Custom memberwise init with `reprompt` defaulted to 0, `attachments` defaulted to `[]`,
    /// `organizationId` defaulted to nil, and `collectionIds` defaulted to `[]` so existing
    /// call sites that pre-date these fields do not need to be updated.
    init(
        id: String, name: String, isFavorite: Bool, isDeleted: Bool,
        creationDate: Date, revisionDate: Date, content: ItemContent,
        reprompt: Int = 0,
        attachments: [Attachment] = [],
        folderId: String? = nil,
        organizationId: String? = nil,
        collectionIds: [String] = []
    ) {
        self.id = id
        self.folderId = folderId
        self.name = name
        self.isFavorite = isFavorite
        self.isDeleted = isDeleted
        self.creationDate = creationDate
        self.revisionDate = revisionDate
        self.content = content
        self.reprompt = reprompt
        self.attachments = attachments
        self.organizationId = organizationId
        self.collectionIds = collectionIds
    }

    /// Encodes this item to a pretty-printed JSON string using ISO 8601 dates.
    ///
    /// The output is the decrypted domain model — plaintext values, not EncString-encoded
    /// wire format. Suitable for consumption by external tools (e.g. `vault-item-to-print`).
    ///
    /// - Returns: A JSON string, or nil if encoding fails.
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Item content discriminator

/// Discriminated union of all five Bitwarden vault item types.
///
/// `Codable` conformance uses a discriminated union with a `"type"` key
/// so JSON output is self-describing and can be consumed by external tools.
nonisolated enum ItemContent: Equatable, Hashable, Codable {
    case login(LoginContent)
    case secureNote(SecureNoteContent)
    case card(CardContent)
    case identity(IdentityContent)
    case sshKey(SSHKeyContent)

    private enum CodingKeys: String, CodingKey {
        case type
        case login
        case secureNote
        case card
        case identity
        case sshKey
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .login(let v):
            try c.encode("login",      forKey: .type)
            try c.encode(v,            forKey: .login)
        case .secureNote(let v):
            try c.encode("secureNote", forKey: .type)
            try c.encode(v,            forKey: .secureNote)
        case .card(let v):
            try c.encode("card",       forKey: .type)
            try c.encode(v,            forKey: .card)
        case .identity(let v):
            try c.encode("identity",   forKey: .type)
            try c.encode(v,            forKey: .identity)
        case .sshKey(let v):
            try c.encode("sshKey",     forKey: .type)
            try c.encode(v,            forKey: .sshKey)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "login":      self = .login(try c.decode(LoginContent.self,        forKey: .login))
        case "secureNote": self = .secureNote(try c.decode(SecureNoteContent.self, forKey: .secureNote))
        case "card":       self = .card(try c.decode(CardContent.self,          forKey: .card))
        case "identity":   self = .identity(try c.decode(IdentityContent.self,  forKey: .identity))
        case "sshKey":     self = .sshKey(try c.decode(SSHKeyContent.self,      forKey: .sshKey))
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "Unknown item content type: \(type)")
        }
    }
}

// MARK: - Login

nonisolated struct LoginContent: Equatable, Hashable, Codable {
    let username: String?
    let password: String?
    let uris: [LoginURI]
    /// Stored TOTP seed. Present on some items but never displayed in v1 (FR-038).
    let totp: String?
    let notes: String?
    let customFields: [CustomField]
}

nonisolated struct LoginURI: Equatable, Hashable, Codable {
    let uri: String
    let matchType: URIMatchType?
}

/// URI-matching strategy used when auto-filling (stored per URI, not used in v1 display).
nonisolated enum URIMatchType: Int, Equatable, Hashable, Codable {
    case domain = 0
    case host = 1
    case startsWith = 2
    case exact = 3
    case regularExpression = 4
    case never = 5
}

// MARK: - Card

nonisolated struct CardContent: Equatable, Hashable, Codable {
    let cardholderName: String?
    let brand: String?
    let number: String?
    let expMonth: String?
    let expYear: String?
    let code: String?
    let notes: String?
    let customFields: [CustomField]
}

// MARK: - Identity

nonisolated struct IdentityContent: Equatable, Hashable, Codable {
    let title: String?
    let firstName: String?
    let middleName: String?
    let lastName: String?
    let address1: String?
    let address2: String?
    let address3: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
    let company: String?
    let email: String?
    let phone: String?
    let ssn: String?
    let username: String?
    let passportNumber: String?
    let licenseNumber: String?
    let notes: String?
    let customFields: [CustomField]
}

// MARK: - Secure Note

nonisolated struct SecureNoteContent: Equatable, Hashable, Codable {
    let notes: String?
    let customFields: [CustomField]
}

// MARK: - SSH Key

nonisolated struct SSHKeyContent: Equatable, Hashable, Codable {
    let privateKey: String?
    let publicKey: String?
    let keyFingerprint: String?
    let notes: String?
    let customFields: [CustomField]
}
