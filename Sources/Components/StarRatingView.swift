import SwiftUI

/// A 0–5 star rating control. When `isEditable` it responds to taps, otherwise
/// it renders a compact read-only summary.
struct StarRatingView: View {
    @Binding var rating: Int
    var isEditable: Bool = true

    var body: some View {
        HStack(spacing: isEditable ? 6 : 4) {
            ForEach(1...5, id: \.self) { star in
                starButton(star)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating) out of 5 stars")
    }

    @ViewBuilder
    private func starButton(_ star: Int) -> some View {
        if isEditable {
            Button {
                Haptics.tap()
                rating = rating == star ? star - 1 : star
            } label: {
                starImage(star)
            }
            .buttonStyle(.plain)
            .minimumTapTarget()
            .accessibilityLabel("\(star) star")
            .accessibilityAddTraits(star <= rating ? .isSelected : [])
        } else {
            starImage(star)
                .accessibilityHidden(true)
        }
    }

    private func starImage(_ star: Int) -> some View {
        Image(systemName: star <= rating ? "star.fill" : "star")
            .foregroundStyle(star <= rating ? .yellow : .secondary)
            .font(isEditable ? .title3 : .body)
    }
}
