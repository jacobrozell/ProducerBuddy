import SwiftUI

extension View {
    /// Root tab chrome: brand tint and grouped background.
    func brandTabChrome() -> some View {
        self
            .tint(Brand.accent)
            .background(Brand.background.ignoresSafeArea())
    }

    /// Branded hero background for splash and onboarding moments.
    func brandHeroBackground() -> some View {
        background {
            ZStack {
                Brand.background
                RadialGradient(
                    colors: [Brand.accent.opacity(0.18), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 420
                )
                LinearGradient(
                    colors: [.clear, Brand.backgroundSecondary.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    /// Settings and form screens on elevated surfaces.
    func brandFormChrome() -> some View {
        scrollContentBackground(.hidden)
            .background(Brand.background.ignoresSafeArea())
            .tint(Brand.accent)
    }

    /// Branded grouped-list row surface for forms and settings sheets.
    func brandFormRowBackground() -> some View {
        listRowBackground(Brand.surface)
    }

    /// Resigns text focus when a non-text control changes (pickers, sliders, toggles).
    func dismissesKeyboardOnChange<V: Equatable>(
        of value: V,
        using dismiss: @escaping () -> Void
    ) -> some View {
        onChange(of: value) { _, _ in dismiss() }
    }
}
