import SwiftUI
import Charts

/// One plotted point on the energy curve: a track's BPM at its running-order
/// position.
struct EnergyPoint: Identifiable {
    let id: UUID
    let position: Int
    let title: String
    let bpm: Int
}

/// A Swift Charts line/area view of a project's BPM across its running order.
/// Seeing the *shape* of a record — the build to a peak, the wind-down — is far
/// more intuitive than reading per-row Rise/Fall badges. The peak track is
/// marked so the user can see where their record crests.
struct EnergyCurveChart: View {
    let points: [EnergyPoint]

    private var peak: EnergyPoint? {
        guard let index = SequencingEngine.peakIndex(bpms: points.map(\.bpm)) else { return nil }
        return points[index]
    }

    var body: some View {
        Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Track", point.position),
                    y: .value("BPM", point.bpm)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    .linearGradient(
                        colors: [.accentColor.opacity(0.35), .accentColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Track", point.position),
                    y: .value("BPM", point.bpm)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Track", point.position),
                    y: .value("BPM", point.bpm)
                )
                .foregroundStyle(point.id == peak?.id ? Color.orange : .accentColor)
                .symbolSize(point.id == peak?.id ? 90 : 45)
            }

            if let peak {
                RuleMark(x: .value("Peak", peak.position))
                    .foregroundStyle(.orange.opacity(0.25))
                    .annotation(position: .top, alignment: .center) {
                        Text("Peak")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartXScale(domain: 0.5...(Double(points.count) + 0.5))
        .chartXAxis {
            AxisMarks(values: points.map(\.position)) { value in
                AxisValueLabel {
                    if let position = value.as(Int.self) {
                        Text("\(position)")
                    }
                }
            }
        }
        .chartYAxisLabel("BPM")
        .frame(height: 160)
    }
}
