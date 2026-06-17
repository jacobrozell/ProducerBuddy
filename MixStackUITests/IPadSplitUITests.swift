import XCTest

final class IPadSplitUITests: MixStackUITestCase {
    func testLibrarySplitShowsSongDetailOnIPad() throws {
        try requireIPad()

        let app = launchAppOnIPad()

        XCTAssertTrue(
            app.descendants(matching: .any)[Self.splitSelectSongID].waitForExistence(timeout: timeout)
        )

        let song = app.staticTexts[Self.seededSongTitle]
        XCTAssertTrue(song.waitForExistence(timeout: timeout))
        song.tap()

        XCTAssertTrue(app.staticTexts["Details"].waitForExistence(timeout: timeout))
    }

    func testProjectsSplitShowsDetailOnIPad() throws {
        try requireIPad()

        let app = launchAppOnIPad()

        tapTab(named: "Projects", in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)[Self.splitSelectProjectID].waitForExistence(timeout: timeout)
        )

        let project = app.staticTexts[Self.seededProjectTitle].firstMatch
        XCTAssertTrue(project.waitForExistence(timeout: timeout))
        project.tap()

        XCTAssertTrue(app.navigationBars[Self.seededProjectTitle].waitForExistence(timeout: timeout))
    }

    private func launchAppOnIPad() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui_test_reset",
            "-disable_analytics",
            "-ui_test_skip_onboarding",
            "-ui_test_seed_catalog"
        ]
        app.launch()
        waitForMainShell(in: app)
        return app
    }
}
