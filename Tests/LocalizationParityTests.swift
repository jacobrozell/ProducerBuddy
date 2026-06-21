import Foundation
import Testing
@testable import MixStack

@Suite("Localization parity")
struct LocalizationParityTests {
    private static var catalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Localizable.xcstrings")
    }

    @Test("English catalog contains every L10n key")
    func englishKeysPresent() throws {
        let data = try Data(contentsOf: Self.catalogURL)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(json["strings"] as? [String: Any])

        let missing = L10n.catalogKeys.filter { strings[$0] == nil }
        #expect(missing.isEmpty, "Missing xcstrings keys: \(missing)")
    }
}
