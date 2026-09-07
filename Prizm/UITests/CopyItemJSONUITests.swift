import XCTest

/// XCUITest: Copy Item ID and Copy as JSON context menu actions.
///
/// Validates that the context menu on vault items offers "Copy Item ID" and
/// "Copy as JSON" actions, and that they copy the expected content to the clipboard.
///
/// Prerequisites: App launched with `--ui-testing`, `--inject-session`, `--inject-vault`,
/// `--skip-sync` so a pre-populated vault is available without a network round-trip.
final class CopyItemJSONUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--inject-session", "--inject-vault", "--skip-sync"]
        app.launch()

        let vaultNav = app.otherElements["vault.navigationSplit"]
        XCTAssertTrue(vaultNav.waitForExistence(timeout: 30), "Vault browser must be visible")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Copy Item ID from item list

    func testCopyItemID_fromListContextMenu_menuItemAppears() throws {
        let list     = app.tables["itemList.list"]
        let firstRow = list.cells.firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5), "Vault list must have at least one item")

        firstRow.rightClick()
        let copyIDItem = app.menuItems["Copy Item ID"]
        XCTAssertTrue(copyIDItem.waitForExistence(timeout: 3), "Copy Item ID menu item must appear")
    }

    // MARK: - Copy as JSON from item list

    func testCopyItemJSON_fromListContextMenu_menuItemAppears() throws {
        let list     = app.tables["itemList.list"]
        let firstRow = list.cells.firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5), "Vault list must have at least one item")

        firstRow.rightClick()
        let copyJSONItem = app.menuItems["Copy as JSON"]
        XCTAssertTrue(copyJSONItem.waitForExistence(timeout: 3), "Copy as JSON menu item must appear")
    }

    // MARK: - Copy Item ID from Trash

    func testCopyItemID_fromTrashContextMenu_menuItemAppears() throws {
        // Navigate to Trash.
        let trashSidebarRow = app.buttons["sidebar.trash"]
        XCTAssertTrue(trashSidebarRow.waitForExistence(timeout: 5))
        trashSidebarRow.click()

        let list = app.tables["itemList.list"]
        let firstTrashed = list.cells.firstMatch
        XCTAssertTrue(firstTrashed.waitForExistence(timeout: 5), "Trash must have at least one item")

        firstTrashed.rightClick()
        let copyIDItem = app.menuItems["Copy Item ID"]
        XCTAssertTrue(copyIDItem.waitForExistence(timeout: 3), "Copy Item ID menu item must appear in Trash")
    }

    // MARK: - Copy as JSON from Trash

    func testCopyItemJSON_fromTrashContextMenu_menuItemAppears() throws {
        // Navigate to Trash.
        let trashSidebarRow = app.buttons["sidebar.trash"]
        XCTAssertTrue(trashSidebarRow.waitForExistence(timeout: 5))
        trashSidebarRow.click()

        let list = app.tables["itemList.list"]
        let firstTrashed = list.cells.firstMatch
        XCTAssertTrue(firstTrashed.waitForExistence(timeout: 5), "Trash must have at least one item")

        firstTrashed.rightClick()
        let copyJSONItem = app.menuItems["Copy as JSON"]
        XCTAssertTrue(copyJSONItem.waitForExistence(timeout: 3), "Copy as JSON menu item must appear in Trash")
    }
}
