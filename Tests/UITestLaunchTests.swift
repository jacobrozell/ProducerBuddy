import Testing
@testable import MixStack

@Suite("UITest launch contract", .tags(.unit))
struct UITestLaunchTests {
    @Test("Reset argument constant is stable")
    func resetArgument() {
        #expect(UITestLaunch.resetArgument == "-ui_test_reset")
        #expect(UITestLaunch.seedCatalogArgument == "-ui_test_seed_catalog")
    }
}
