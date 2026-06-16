import SwiftUI

/// Draws a waveform from normalized peaks using a `Canvas`. The portion up to
/// `progress` (0–1) is tinted as "played"; tapping or dragging reports the
/// touched fraction via `onSeek` for scrubbing.
struct WaveformView: View {
    let samples: [Float]
    var progress: Double = 0
    var playedColor: Color = .accentColor
    var unplayedColor: Color = Color(.systemGray3)
    var onSeek: ((Double) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                guard !samples.isEmpty else { return }
                let slot = size.width / CGFloat(samples.count)
                let barWidth = max(1, slot * 0.7)
                let midY = size.height / 2

                for (index, sample) in samples.enumerated() {
                    let x = CGFloat(index) * slot + (slot - barWidth) / 2
                    let height = max(2, CGFloat(sample) * size.height)
                    let rect = CGRect(x: x, y: midY - height / 2, width: barWidth, height: height)
                    let fraction = (Double(index) + 0.5) / Double(samples.count)
                    let color = fraction <= progress ? playedColor : unplayedColor
                    context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2), with: .color(color))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let onSeek else { return }
                        onSeek(clampedFraction(value.location.x, width: geo.size.width))
                    }
            )
        }
    }

    private func clampedFraction(_ x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return Double(min(max(x / width, 0), 1))
    }
}
