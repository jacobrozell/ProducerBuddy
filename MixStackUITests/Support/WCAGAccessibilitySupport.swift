import XCTest

/// Maps Apple's automated accessibility audits to WCAG 2.1 AA checks.
enum WCAGAccessibilityAuditProfile {
    static let nameRoleValue: XCUIAccessibilityAuditType = [.elementDetection, .sufficientElementDescription]
    static let touchTargets: XCUIAccessibilityAuditType = .hitRegion
}

extension MixStackUITestCase {
    func runWCAGAudit(
        on app: XCUIApplication,
        auditTypes: XCUIAccessibilityAuditType,
        ignoring issueFilter: (@Sendable (XCUIAccessibilityAuditIssue) -> Bool)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            try app.performAccessibilityAudit(for: auditTypes) { issue in
                issueFilter?(issue) ?? false
            }
        } catch {
            XCTFail(
                "WCAG accessibility audit failed (\(auditTypes)): \(error.localizedDescription)",
                file: file,
                line: line
            )
        }
    }

    /// Root tab chrome uses system metrics on iPhone and iPad sidebar tabs.
    static func ignoringRootNavigationChrome(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        guard issue.auditType == .hitRegion else { return false }
        let description = issue.compactDescription
        return description.localizedCaseInsensitiveContains("Library")
            || description.localizedCaseInsensitiveContains("Projects")
    }
}
