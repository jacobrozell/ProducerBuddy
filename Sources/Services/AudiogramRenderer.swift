import AVFoundation
import CoreGraphics
import UIKit

enum AudiogramError: Error {
    case missingAudio
    case writerFailed
    case exportFailed
}

/// Renders a short branded MP4 teaser with animated waveform bars.
enum AudiogramRenderer {
    struct ExportOptions: Sendable {
        let startTime: Double
        let duration: Double
        let format: CardFormat
        let reduceMotion: Bool
    }

    /// Plain-value export input — safe to pass off the main actor.
    struct Request: Sendable {
        let audioFileURL: URL
        let mixDuration: Double
        let mixDisplayName: String
        let waveform: [Float]
        let songTitle: String
        let songMeta: String
        let subtitle: String
        let startTime: Double
        let duration: Double
        let format: CardFormat
        let accentHex: String
        let footerText: String
        let cardStyle: BrandCardStyle
        let logoPath: String?
        let reduceMotion: Bool

        @MainActor
        static func make(
            mix: Mix,
            song: Song,
            options: ExportOptions,
            brand: BrandKitSettings.Snapshot
        ) -> Request {
            Request(
                audioFileURL: mix.fileURL,
                mixDuration: mix.duration,
                mixDisplayName: mix.displayName,
                waveform: mix.waveform,
                songTitle: song.title,
                songMeta: "\(song.bpm) BPM · \(song.key.displayName)",
                subtitle: brand.creditLine(for: song) ?? mix.displayName,
                startTime: options.startTime,
                duration: options.duration,
                format: options.format,
                accentHex: brand.accentHex,
                footerText: brand.footerText,
                cardStyle: brand.cardStyle,
                logoPath: brand.logoURL?.path,
                reduceMotion: options.reduceMotion
            )
        }
    }

    private static let fps: Int32 = 30

    static func export(
        _ request: Request,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        try Task.checkCancellation()
        let snippetDuration = min(request.duration, 30, max(0, request.mixDuration - request.startTime))
        guard snippetDuration > 0 else { throw AudiogramError.missingAudio }

        progress?(0.05)
        let audioURL = try await exportTrimmedAudio(
            source: request.audioFileURL,
            start: request.startTime,
            duration: snippetDuration
        )
        progress?(0.25)

        try Task.checkCancellation()
        let size = pixelSize(for: request.format)
        let videoURL = try await exportVideo(
            request: request,
            snippetDuration: snippetDuration,
            size: size,
            progress: { value in progress?(0.25 + value * 0.55) }
        )
        progress?(0.85)

        try Task.checkCancellation()
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("audiogram-\(UUID().uuidString).mp4")
        try await mux(videoURL: videoURL, audioURL: audioURL, outputURL: outputURL)
        try? FileManager.default.removeItem(at: audioURL)
        try? FileManager.default.removeItem(at: videoURL)
        progress?(1)
        return outputURL
    }

    private static func exportTrimmedAudio(
        source: URL,
        start: Double,
        duration: Double
    ) async throws -> URL {
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw AudiogramError.exportFailed
        }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("audiogram-audio-\(UUID().uuidString).m4a")
        session.timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 600),
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )
        try await session.export(to: output, as: .m4a)
        return output
    }

    private static func exportVideo(
        request: Request,
        snippetDuration: Double,
        size: CGSize,
        progress: (@Sendable (Double) -> Void)?
    ) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("audiogram-video-\(UUID().uuidString).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(size.width),
                AVVideoHeightKey: Int(size.height)
            ]
        )
        videoInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height)
            ]
        )

        guard writer.canAdd(videoInput) else { throw AudiogramError.writerFailed }
        writer.add(videoInput)
        guard writer.startWriting() else { throw AudiogramError.writerFailed }
        writer.startSession(atSourceTime: .zero)

        let frameCount = max(1, Int(snippetDuration * Double(fps)))

        var frameIndex = 0
        while frameIndex < frameCount {
            try Task.checkCancellation()
            while !videoInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 5_000_000)
                try Task.checkCancellation()
            }
            let progressFraction = request.reduceMotion
                ? 0.5
                : Double(frameIndex) / Double(max(frameCount - 1, 1))
            let centerTime = request.startTime + progressFraction * snippetDuration
            let buffer = drawFrame(request: request, size: size, centerTime: centerTime)
            let frameTime = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
            adaptor.append(buffer, withPresentationTime: frameTime)
            frameIndex += 1
            progress?(Double(frameIndex) / Double(frameCount))
        }

        videoInput.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw AudiogramError.exportFailed }
        return outputURL
    }

    private static func mux(videoURL: URL, audioURL: URL, outputURL: URL) async throws {
        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)

        guard
            let videoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            let sourceVideo = try await videoAsset.loadTracks(withMediaType: .video).first,
            let audioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            let sourceAudio = try await audioAsset.loadTracks(withMediaType: .audio).first
        else { throw AudiogramError.exportFailed }

        let videoDuration = try await videoAsset.load(.duration)
        let audioDuration = try await audioAsset.load(.duration)
        let duration = CMTimeMinimum(videoDuration, audioDuration)
        let range = CMTimeRange(start: .zero, duration: duration)

        try videoTrack.insertTimeRange(range, of: sourceVideo, at: .zero)
        try audioTrack.insertTimeRange(range, of: sourceAudio, at: .zero)

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else { throw AudiogramError.exportFailed }

        try await exporter.export(to: outputURL, as: .mp4)
    }

    private static func pixelSize(for format: CardFormat) -> CGSize {
        switch format {
        case .square: return CGSize(width: 1080, height: 1080)
        case .banner: return CGSize(width: 1920, height: 1080)
        case .story: return CGSize(width: 1080, height: 1920)
        }
    }

    private static func drawFrame(
        request: Request,
        size: CGSize,
        centerTime: Double
    ) -> CVPixelBuffer {
        let logo = request.logoPath.flatMap { UIImage(contentsOfFile: $0) }
        return AudiogramFrameDrawer.makePixelBuffer(
            AudiogramFrameDrawer.Content(
                size: size,
                title: request.songTitle,
                subtitle: request.subtitle,
                meta: request.songMeta,
                footer: request.footerText,
                accent: uiColor(hexRGB: request.accentHex) ?? .systemPurple,
                cardStyle: request.cardStyle,
                peaks: request.waveform,
                centerTime: centerTime,
                trackDuration: max(request.mixDuration, 0.01),
                logo: logo
            )
        )
    }

    private static func uiColor(hexRGB hex: String) -> UIColor? {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&value) else { return nil }
        return UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
