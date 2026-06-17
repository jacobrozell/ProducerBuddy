import XCTest

/// Shared launch configuration for MixStack UI tests.
class MixStackUITestCase: XCTestCase {
    static let seededSongTitle = "UITest Song"
    static let seededProjectTitle = "UITest EP"
    static let settingsButtonID = "settings.button"
    static let splitSelectSongID = "split.selectSong"
    static let splitSelectProjectID = "split.selectProject"

    let timeout: TimeInterval = 12

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        resetSimulatorOrientationToPortrait()
    }

    override func tearDown() {
        resetSimulatorOrientationToPortrait()
        XCUIApplication().terminate()
        super.tearDown()
    }

    func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui_test_reset",
            "-disable_analytics",
            "-ui_test_skip_onboarding",
            "-ui_test_seed_catalog"
        ] + extraArguments
        app.launch()
        waitForMainShell(in: app)
        return app
    }

    /// Waits until the root tab shell is visible (tab bar on iPhone, sidebar tabs on iPad).
    func waitForMainShell(in app: XCUIApplication) {
        let tabBarReady = app.tabBars.firstMatch.waitForExistence(timeout: 2)
        if tabBarReady { return }

        let libraryTab = app.buttons["Library"].firstMatch
        XCTAssertTrue(libraryTab.waitForExistence(timeout: timeout), "Main shell did not appear")
    }

    func tapTab(named name: String, in app: XCUIApplication) {
        let tabBarTab = app.tabBars.buttons[name]
        if tabBarTab.waitForExistence(timeout: 2) {
            tabBarTab.tap()
            return
        }

        // iPad regular width: SwiftUI TabView uses a sidebar instead of a tab bar.
        let sidebarTab = app.buttons[name].firstMatch
        XCTAssertTrue(sidebarTab.waitForExistence(timeout: timeout), "Missing tab \(name)")
        sidebarTab.tap()
    }

    func resetSimulatorOrientationToPortrait() {
        if XCUIDevice.shared.orientation != .portrait {
            XCUIDevice.shared.orientation = .portrait
        }
    }

    func rotateToLandscapeLeft(app: XCUIApplication) {
        XCUIDevice.shared.orientation = .landscapeLeft
        RunLoop.current.run(until: Date().addingTimeInterval(0.75))
        waitForMainShell(in: app)
    }

    /// Skips when the UI test bundle is not running on an iPad simulator.
    func requireIPad() throws {
        let isPad = MainActor.assumeIsolated { UIDevice.current.userInterfaceIdiom == .pad }
        guard isPad else {
            throw XCTSkip("Requires iPad simulator")
        }
    }
}
