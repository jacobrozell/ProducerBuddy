import Foundation
import UIKit

/// Stores brand kit images under `Documents/Brand/`.
enum BrandStorage {
    static var brandDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Brand", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(for fileName: String) -> URL {
        brandDirectory.appendingPathComponent(fileName)
    }

    /// Saves a picked logo image, downscaling to 512 px on the longest edge.
    @discardableResult
    static func importLogo(from sourceURL: URL) throws -> String {
        let needsStop = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsStop { sourceURL.stopAccessingSecurityScopedResource() } }

        guard let image = UIImage(contentsOfFile: sourceURL.path) else {
            throw BrandStorageError.invalidImage
        }
        let scaled = downscale(image, maxDimension: 512)
        guard let data = scaled.pngData() else { throw BrandStorageError.invalidImage }

        let fileName = "\(UUID().uuidString).png"
        let destination = brandDirectory.appendingPathComponent(fileName)
        try data.write(to: destination, options: .atomic)
        return fileName
    }

    static func importLogo(image: UIImage) throws -> String {
        let scaled = downscale(image, maxDimension: 512)
        guard let data = scaled.pngData() else { throw BrandStorageError.invalidImage }
        let fileName = "\(UUID().uuidString).png"
        let destination = brandDirectory.appendingPathComponent(fileName)
        try data.write(to: destination, options: .atomic)
        return fileName
    }

    static func deleteFile(named fileName: String) {
        let url = brandDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    static func clearAll() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: brandDirectory,
            includingPropertiesForKeys: nil
        ) else { return }
        for url in contents {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum BrandStorageError: Error {
    case invalidImage
}
