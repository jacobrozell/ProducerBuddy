import Foundation

/// Single registry for every external URL the app links to. Keeping them here
/// (rather than scattered string literals) means the legal/support URLs Apple
/// requires live in one auditable place. An optional link that is `nil` is
/// simply hidden in the UI.
enum AppLinks {
    /// Base GitHub Pages site for this repo; legal pages are served from `/docs`.
    private static let site = "https://jacobrozell.github.io/mixstack"

    static let privacy = URL(string: "\(site)/privacy.html")!
    static let support = URL(string: "\(site)/support.html")!
    static let accessibility = URL(string: "\(site)/accessibility.html")!

    /// App Store review link. Set once the app has a listing.
    static let appStoreReview: URL? = nil

    /// Optional "buy me a coffee"-style tip link. `nil` hides the row entirely.
    static let tipJar: URL? = URL(string: "https://buymeacoffee.com/jacobrozelq")
}
