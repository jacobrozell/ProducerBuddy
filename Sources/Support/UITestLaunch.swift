import Foundation

/// Launch-argument contract for UI and integration tests.
enum UITestLaunch {
    static let resetArgument = "-ui_test_reset"
    static let skipOnboardingArgument = "-ui_test_skip_onboarding"
    static let seedCatalogArgument = "-ui_test_seed_catalog"

    static var isUITestReset: Bool {
        ProcessInfo.processInfo.arguments.contains(resetArgument)
    }

    static var shouldSkipOnboarding: Bool {
        isUITestReset
            || ProcessInfo.processInfo.arguments.contains(skipOnboardingArgument)
    }

    static var shouldSeedCatalog: Bool {
        ProcessInfo.processInfo.arguments.contains(seedCatalogArgument)
    }

    /// Clears demo audio and onboarding flags so UI tests start from a known state.
    static func prepareAppDefaultsIfNeeded() {
        guard isUITestReset else { return }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        clearAudioDirectory()
    }

    private static func clearAudioDirectory() {
        let directory = AudioStorage.audioDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        for url in contents {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
