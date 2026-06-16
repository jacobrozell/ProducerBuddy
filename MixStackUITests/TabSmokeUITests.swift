import XCTest

final class TabSmokeUITests: MixStackUITestCase {
    func testLibraryAndProjectsTabsShowSeededCatalog() {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts[Self.seededSongTitle].waitForExistence(timeout: timeout))

        tapTab(named: "Projects", in: app)
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts[Self.seededProjectTitle].waitForExistence(timeout: timeout))
    }

    func testSettingsSheetOpensFromLibrary() {
        let app = launchApp()

        let settings = app.buttons[Self.settingsButtonID]
        XCTAssertTrue(settings.waitForExistence(timeout: timeout))
        settings.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: timeout))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: timeout))
    }
}
