import SwiftUI

/// Song-detail row showing vocal presence and an auto-detect confidence meter.
struct VocalConfidenceMeter: View {
    let presence: VocalPresence
    let confidence: Double?
    let isManual: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: displaySymbol)
                    .foregroundStyle(displayTint)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(presenceLabel)
                        .font(.body)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                if let percentText {
                    Text(percentText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            if showsMeter, let confidence {
                ConfidenceCapsule(value: confidence, tint: meterTint)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(A11yID.Song.vocalMeter)
    }

    private var showsMeter: Bool {
        !isManual && confidence != nil
    }

    private var displaySymbol: String {
        if isManual { return presence.symbolName }
        guard let confidence else { return presence.symbolName }
        if VocalDetectionThresholds.isLabeled(confidence) { return presence.symbolName }
        if VocalDetectionThresholds.isUncertain(confidence) { return "questionmark.circle" }
        return "waveform.and.mic"
    }

    private var displayTint: Color {
        if isManual { return .primary }
        guard let confidence else { return .secondary }
        if VocalDetectionThresholds.isLabeled(confidence) { return .accentColor }
        if VocalDetectionThresholds.isUncertain(confidence) { return .secondary }
        return .secondary
    }

    private var presenceLabel: String {
        if isManual { return presence.displayName }
        guard let confidence else { return presence.displayName }
        if VocalDetectionThresholds.isLabeled(confidence) { return presence.displayName }
        if VocalDetectionThresholds.isUncertain(confidence) { return "Uncertain" }
        return presence.displayName
    }

    private var subtitle: String? {
        if isManual { return "Set manually" }
        guard let confidence else { return nil }
        if VocalDetectionThresholds.isUncertain(confidence) {
            return uncertainLean(confidence)
        }
        if VocalDetectionThresholds.isLabeled(confidence) {
            return "Detected automatically"
        }
        return nil
    }

    private var percentText: String? {
        guard !isManual, let confidence, confidence >= VocalDetectionThresholds.minimum else { return nil }
        let percent = Int((confidence * 100).rounded())
        return "\(percent)%"
    }

    private var meterTint: Color {
        guard let confidence else { return .secondary }
        if confidence >= VocalDetectionThresholds.strong { return .accentColor }
        if VocalDetectionThresholds.isLabeled(confidence) { return .accentColor.opacity(0.85) }
        return .secondary
    }

    private var accessibilityLabel: String {
        if isManual {
            return "\(presence.displayName), set manually"
        }
        guard let confidence else { return "Vocals not analyzed" }
        let percent = Int((confidence * 100).rounded())
        if VocalDetectionThresholds.isLabeled(confidence) {
            return "\(presence.displayName), \(percent) percent confidence, automatically detected"
        }
        if VocalDetectionThresholds.isUncertain(confidence) {
            let lean = uncertainLean(confidence) ?? "uncertain"
            return "Uncertain, \(percent) percent confidence, \(lean)"
        }
        return "Vocals not analyzed"
    }

    private func uncertainLean(_ confidence: Double) -> String? {
        guard presence != .unknown else {
            return confidence >= 0.5 ? "leans toward vocals" : "leans instrumental"
        }
        return "between instrumental and vocals"
    }
}

/// Horizontal confidence bar used on song detail.
private struct ConfidenceCapsule: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                Capsule()
                    .fill(tint)
                    .frame(width: max(4, geometry.size.width * value))
            }
        }
        .frame(height: 6)
    }
}
