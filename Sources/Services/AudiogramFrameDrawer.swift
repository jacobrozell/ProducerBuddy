import CoreGraphics
import UIKit

/// Draws a single audiogram video frame into a pixel buffer.
enum AudiogramFrameDrawer {
    struct Content {
        let size: CGSize
        let title: String
        let subtitle: String
        let meta: String
        let footer: String
        let accent: UIColor
        let cardStyle: BrandCardStyle
        let peaks: [Float]
        let centerTime: Double
        let trackDuration: Double
        let logo: UIImage?
    }

    private static let barCount = 48

    static func makePixelBuffer(_ content: Content) -> CVPixelBuffer {
        let width = Int(content.size.width)
        let height = Int(content.size.height)
        var pixelBuffer: CVPixelBuffer!
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return pixelBuffer }

        drawBackground(context: context, content: content)
        drawText(context: context, content: content, width: width, height: height)
        drawWaveform(context: context, content: content, width: width, height: height)
        drawLogo(context: context, content: content, width: width)
        return pixelBuffer
    }

    private static func drawBackground(context: CGContext, content: Content) {
        context.setFillColor(content.accent.cgColor)
        context.fill(CGRect(origin: .zero, size: content.size))
        guard content.cardStyle != .minimal else { return }
        context.setFillColor(UIColor.black.withAlphaComponent(0.18).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: content.size.width, height: content.size.height / 2))
    }

    private static func drawText(context: CGContext, content: Content, width: Int, height: Int) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let inset = CGRect(x: 64, y: 0, width: width - 128, height: height)

        (content.title as NSString).draw(
            in: CGRect(x: inset.minX, y: 120, width: inset.width, height: 160),
            withAttributes: titleAttributes(paragraph)
        )
        (content.subtitle as NSString).draw(
            in: CGRect(x: inset.minX, y: 280, width: inset.width, height: 60),
            withAttributes: subtitleAttributes(paragraph)
        )
        (content.meta as NSString).draw(
            in: CGRect(x: inset.minX, y: 350, width: inset.width, height: 44),
            withAttributes: metaAttributes(paragraph)
        )
        (content.footer as NSString).draw(
            in: CGRect(x: inset.minX, y: CGFloat(height) - 90, width: inset.width, height: 30),
            withAttributes: footerAttributes(paragraph)
        )
    }

    private static func drawWaveform(context: CGContext, content: Content, width: Int, height: Int) {
        let bars = WaveformSlice.visiblePeaks(
            samples: content.peaks,
            centerTime: content.centerTime,
            trackDuration: content.trackDuration,
            barCount: barCount
        )
        let barRegion = CGRect(x: 64, y: height - 280, width: width - 128, height: 180)
        let slot = barRegion.width / CGFloat(bars.count)
        context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        for (index, sample) in bars.enumerated() {
            let barWidth = max(3, slot * 0.65)
            let barHeight = CGFloat(sample) * barRegion.height
            let x = barRegion.minX + CGFloat(index) * slot + (slot - barWidth) / 2
            let rect = CGRect(
                x: x,
                y: barRegion.midY - barHeight / 2,
                width: barWidth,
                height: max(6, barHeight)
            )
            context.fill(rect)
        }
    }

    private static func drawLogo(context: CGContext, content: Content, width: Int) {
        guard let logo = content.logo else { return }
        let logoRect = CGRect(x: width - 140, y: 64, width: 72, height: 72)
        context.saveGState()
        context.addPath(UIBezierPath(roundedRect: logoRect, cornerRadius: 12).cgPath)
        context.clip()
        logo.draw(in: logoRect)
        context.restoreGState()
    }

    private static func titleAttributes(_ paragraph: NSParagraphStyle) -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 56, weight: .heavy),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
    }

    private static func subtitleAttributes(_ paragraph: NSParagraphStyle) -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 34, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9),
            .paragraphStyle: paragraph
        ]
    }

    private static func metaAttributes(_ paragraph: NSParagraphStyle) -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 26, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.85),
            .paragraphStyle: paragraph
        ]
    }

    private static func footerAttributes(_ paragraph: NSParagraphStyle) -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.75),
            .paragraphStyle: paragraph
        ]
    }
}
