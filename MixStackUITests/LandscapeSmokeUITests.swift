import XCTest

final class LandscapeSmokeUITests: MixStackUITestCase {
    func testLibraryRemainsUsableInLandscape() {
        let app = launchApp()
        rotateToLandscapeLeft(app: app)

        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts[Self.seededSongTitle].waitForExistence(timeout: timeout))

        let settings = app.buttons[Self.settingsButtonID]
        XCTAssertTrue(settings.waitForExistence(timeout: timeout))
    }

    func testProjectsTabInLandscape() {
        let app = launchApp()
        rotateToLandscapeLeft(app: app)

        tapTab(named: "Projects", in: app)
        XCTAssertTrue(app.staticTexts[Self.seededProjectTitle].waitForExistence(timeout: timeout))
    }
}
