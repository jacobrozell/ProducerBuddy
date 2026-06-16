import XCTest

/// Automated WCAG regression checks for core MixStack screens.
final class WCAGAccessibilityUITests: MixStackUITestCase {
    func testLibraryPassesAccessibilityAudits() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: timeout))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets) { issue in
            Self.ignoringRootNavigationChrome(issue)
        }
    }

    func testSongDetailPassesAccessibilityAudits() {
        let app = launchApp()
        let song = app.staticTexts[Self.seededSongTitle].firstMatch
        XCTAssertTrue(song.waitForExistence(timeout: timeout))
        song.tap()
        XCTAssertTrue(app.navigationBars[Self.seededSongTitle].waitForExistence(timeout: timeout))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testProjectsPassesAccessibilityAudits() {
        let app = launchApp()
        tapTab(named: "Projects", in: app)
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: timeout))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets) { issue in
            Self.ignoringRootNavigationChrome(issue)
        }
    }

    func testSettingsPassesAccessibilityAudits() {
        let app = launchApp()
        let settings = app.buttons[Self.settingsButtonID]
        XCTAssertTrue(settings.waitForExistence(timeout: timeout))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: timeout))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }
}
