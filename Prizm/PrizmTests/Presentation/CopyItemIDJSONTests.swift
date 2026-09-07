import XCTest
@testable import Prizm

@MainActor
final class CopyItemIDJSONTests: XCTestCase {

    private var vault:    MockVaultRepository!
    private var syncRepo: MockSyncTimestampRepository!
    private var sut:      VaultBrowserViewModel!

    override func setUp() async throws {
        try await super.setUp()
        vault    = MockVaultRepository()
        syncRepo = MockSyncTimestampRepository(storedDate: nil)
        sut = makeViewModel()
    }

    private func makeViewModel() -> VaultBrowserViewModel {
        let repo    = MockSyncTimestampRepository(storedDate: nil)
        syncRepo    = repo
        let useCase = GetLastSyncDateUseCaseImpl(repository: repo)
        return VaultBrowserViewModel(
            vault:           vault,
            search:          SearchVaultUseCaseImpl(vault: vault),
            delete:          StubVaultDeleteUseCase(),
            permanentDelete: StubVaultPermanentDeleteUseCase(),
            restore:         StubVaultRestoreUseCase(),
            createFolder:     StubCreateFolder(),
            renameFolder:     StubRenameFolder(),
            deleteFolder:     StubDeleteFolder(),
            moveItem:         StubMoveItem(),
            createCollection: StubCreateCollection(),
            renameCollection: StubRenameCollection(),
            deleteCollection: StubDeleteCollection(),
            syncTimestamp:    repo,
            getLastSyncDate:  useCase
        )
    }

    // MARK: - Copy Item ID

    func testCopyItemIDCopiesUUIDToPasteboard() {
        NSPasteboard.general.clearContents()
        sut.copyItemID("abc-123-def")
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "abc-123-def")
    }

    // MARK: - Copy as JSON

    func testCopyItemJSONCopiesValidJSONToPasteboard() {
        let item = VaultItem(
            id: "json-test-1",
            name: "Test Item",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .login(LoginContent(
                username: "user",
                password: "pass",
                uris: [],
                totp: nil,
                notes: nil,
                customFields: []
            ))
        )
        NSPasteboard.general.clearContents()
        sut.copyItemJSON(item)
        let clipboardContent = NSPasteboard.general.string(forType: .string)
        XCTAssertNotNil(clipboardContent)
        // Verify it's valid JSON by parsing it
        let data = clipboardContent!.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
        // Verify the ID is present
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["id"] as? String, "json-test-1")
        XCTAssertEqual(json["name"] as? String, "Test Item")
    }

    func testCopyItemJSONContainsContentWithType() {
        let item = VaultItem(
            id: "json-test-2",
            name: "Card Item",
            isFavorite: false,
            isDeleted: false,
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            revisionDate: Date(timeIntervalSince1970: 1_700_000_000),
            content: .card(CardContent(
                cardholderName: "John",
                brand: "Visa",
                number: "4111",
                expMonth: "12",
                expYear: "2030",
                code: "123",
                notes: nil,
                customFields: []
            ))
        )
        NSPasteboard.general.clearContents()
        sut.copyItemJSON(item)
        let content = NSPasteboard.general.string(forType: .string)!
        let data = content.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let contentDict = json["content"] as! [String: Any]
        XCTAssertEqual(contentDict["type"] as? String, "card")
    }
}

// MARK: - Stubs

private final class StubVaultDeleteUseCase: DeleteVaultItemUseCase {
    func execute(id: String) async throws {}
}
private final class StubVaultPermanentDeleteUseCase: PermanentDeleteVaultItemUseCase {
    func execute(id: String) async throws {}
}
private final class StubVaultRestoreUseCase: RestoreVaultItemUseCase {
    func execute(id: String) async throws {}
}
private struct StubCreateFolder: CreateFolderUseCase {
    func execute(name: String) async throws -> Folder { Folder(id: "stub", name: name) }
}
private struct StubRenameFolder: RenameFolderUseCase {
    func execute(id: String, name: String) async throws -> Folder { Folder(id: id, name: name) }
}
private struct StubDeleteFolder: DeleteFolderUseCase {
    func execute(id: String) async throws {}
}
private struct StubMoveItem: MoveItemToFolderUseCase {
    func execute(itemId: String, folderId: String?) async throws {}
    func execute(itemIds: [String], folderId: String?) async throws {}
}
private struct StubCreateCollection: CreateCollectionUseCase {
    func execute(name: String, organizationId: String) async throws -> OrgCollection {
        OrgCollection(id: "stub", organizationId: organizationId, name: name)
    }
}
private struct StubRenameCollection: RenameCollectionUseCase {
    func execute(collectionId: String, name: String, organizationId: String) async throws -> OrgCollection {
        OrgCollection(id: collectionId, organizationId: organizationId, name: name)
    }
}
private struct StubDeleteCollection: DeleteCollectionUseCase {
    func execute(collectionId: String, organizationId: String) async throws {}
}
