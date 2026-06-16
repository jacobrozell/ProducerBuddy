import Foundation

/// Feature toggles for optional product infrastructure. Analytics ships off by default
/// (see docs/privacy.html); enable in dogfood with `-enable_analytics`.
enum FeatureFlags {
    static var analyticsEnabled: Bool {
        if CommandLine.arguments.contains("-disable_analytics") { return false }
        if CommandLine.arguments.contains("-enable_analytics") { return true }
        return false
    }

    static var uiTestMode: Bool {
        UITestLaunch.isUITestReset
    }
}
