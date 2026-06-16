import SwiftUI

/// First-run introduction. Explains the core workflow across a few swipeable
/// pages and calls `onFinish` when the user is done (or skips). Shown once,
/// gated by `@AppStorage("hasCompletedOnboarding")` in `RootView`.
struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 140

    let onFinish: () -> Void

    @State private var selection = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "music.note.house",
            tint: Brand.accent,
            title: "Welcome to MixStack",
            message: "Your home for the music you make — from first idea to finished release."
        ),
        OnboardingPage(
            symbol: "square.and.arrow.down",
            tint: Brand.accentBright,
            title: "Build Your Library",
            message: "Import tracks straight from your DAW. MixStack auto-detects BPM and key "
                + "and draws a waveform for each one."
        ),
        OnboardingPage(
            symbol: "waveform.badge.plus",
            tint: Brand.accent,
            title: "Find the Best Take",
            message: "Keep every mix of a song, then A/B them in the player without losing your place "
                + "to pick the winner."
        ),
        OnboardingPage(
            symbol: "square.stack.3d.up",
            tint: Brand.accentBright,
            title: "Sequence Your Release",
            message: "Drag tracks into order and let the app flag energy dips, abrupt tempo jumps, "
                + "and key clashes — or suggest an order for you."
        ),
        OnboardingPage(
            symbol: "photo",
            tint: Brand.accent,
            title: "Share It Beautifully",
            message: "Turn any song or project into a clean, on-brand release card to post anywhere."
        )
    ]

    private var compactHeight: Bool {
        AdaptiveLayout.isCompactHeight(verticalSizeClass)
    }

    private var isLastPage: Bool { selection == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip", action: onFinish)
                    .padding()
                    .minimumTapTarget()
                    .accessibilityHint("Skips the introduction")
            }

            TabView(selection: $selection) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    pageView(page).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: compactHeight ? .never : .always))
            .indexViewStyle(.page(backgroundDisplayMode: compactHeight ? .never : .always))

            Button(action: advance) {
                Text(isLastPage ? "Get Started" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Brand.accent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, compactHeight ? 12 : 24)
            .accessibilityIdentifier("onboarding.primaryButton")
        }
        .brandHeroBackground()
        .interactiveDismissDisabled()
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        ScrollView {
            VStack(spacing: compactHeight ? 16 : 28) {
                ZStack {
                    Circle()
                        .fill(page.tint.gradient)
                        .frame(
                            width: AdaptiveLayout.onboardingHeroSize(
                                compactHeight: compactHeight,
                                scaled: heroSize
                            ),
                            height: AdaptiveLayout.onboardingHeroSize(
                                compactHeight: compactHeight,
                                scaled: heroSize
                            )
                        )
                    Image(systemName: page.symbol)
                        .font(.system(size: compactHeight ? 36 : 60))
                        .foregroundStyle(Brand.textOnAccent)
                }
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(page.title)
                        .font(DS.Typography.display(compactHeight ? .title2 : .title))
                        .multilineTextAlignment(.center)
                    Text(page.message)
                        .font(.body)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, compactHeight ? 20 : 32)
            }
            .padding(.vertical, compactHeight ? 8 : 16)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .combine)
    }

    private func advance() {
        if isLastPage {
            onFinish()
        } else {
            withAnimation(reduceMotion ? nil : .snappy) {
                selection += 1
            }
        }
    }
}

/// A single onboarding page.
private struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let tint: Color
    let title: String
    let message: String
}
