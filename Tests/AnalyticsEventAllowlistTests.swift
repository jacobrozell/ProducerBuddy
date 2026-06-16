import Testing
@testable import MixStack

@Suite("Analytics allowlist", .tags(.unit))
struct AnalyticsEventAllowlistTests {
    @Test("Shipped events are allowlisted")
    func allowedEvents() {
        #expect(AnalyticsEventAllowlist.allowed("app_launched"))
        #expect(AnalyticsEventAllowlist.allowed("main_tab_presented"))
        #expect(AnalyticsEventAllowlist.allowed("song_imported"))
    }

    @Test("Unknown events are rejected")
    func rejectedEvents() {
        #expect(!AnalyticsEventAllowlist.allowed("secret_song_title"))
        #expect(!AnalyticsEventAllowlist.allowed("user_email"))
    }
}
