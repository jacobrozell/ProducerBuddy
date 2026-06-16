import SwiftUI

struct ImportProgressBannerView: View {
    let current: Int
    let total: Int
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Importing \(current) of \(total)…")
                .font(.subheadline)
            Spacer()
            Button("Cancel", role: .cancel, action: onCancel)
                .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Importing \(current) of \(total)")
        .accessibilityIdentifier(A11yID.Library.importProgress)
    }
}

struct ImportSuccessBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .foregroundStyle(.green)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: message) {
                try? await Task.sleep(for: .seconds(2))
                onDismiss()
            }
    }
}
