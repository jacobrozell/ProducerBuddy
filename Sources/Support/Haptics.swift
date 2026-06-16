import UIKit

/// Thin wrapper over `UIFeedbackGenerator` that respects the user's haptics
/// preference (Settings → Feedback). Calls are cheap no-ops when disabled.
@MainActor
enum Haptics {
    /// Backed by `@AppStorage("hapticsEnabled")`; defaults to on.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    /// A light tap for routine actions (play, toggle).
    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// A success notification for completed actions (import finished, etc.).
    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
