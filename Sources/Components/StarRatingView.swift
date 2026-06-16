import SwiftUI

/// A 0–5 star rating control. When `isEditable` it responds to taps, otherwise
/// it renders a compact read-only summary.
struct StarRatingView: View {
    @Binding var rating: Int
    var isEditable: Bool = true

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? .yellow : .secondary)
                    .onTapGesture {
                        guard isEditable else { return }
                        // Tapping the current rating's last star clears it.
                        rating = (rating == star) ? star - 1 : star
                    }
            }
        }
        .font(.subheadline)
    }
}
