import Foundation

/// Minimal store-only ZIP writer/reader for catalog bundles.
enum ZipArchive {
    enum ZipError: Error {
        case invalidArchive
        case writeFailed
    }

    static func createArchive(from sourceDirectory: URL, to destinationZip: URL) throws {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(
            at: sourceDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var entries: [(path: String, data: Data)] = []
        while let url = enumerator?.nextObject() as? URL {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { continue }
            let relative = url.path.replacingOccurrences(of: sourceDirectory.path + "/", with: "")
            let data = try Data(contentsOf: url)
            entries.append((relative, data))
        }

        var archive = Data()
        var centralDirectory = Data()
        var offset: UInt32 = 0

        for entry in entries.sorted(by: { $0.path < $1.path }) {
            let pathData = Data(entry.path.utf8)
            let crc = crc32(entry.data)
            let localHeader = localFileHeader(
                pathLength: UInt16(pathData.count),
                dataSize: UInt32(entry.data.count),
                crc: crc,
                offset: offset
            )
            archive.append(localHeader)
            archive.append(pathData)
            archive.append(entry.data)

            centralDirectory.append(centralFileHeader(
                pathLength: UInt16(pathData.count),
                dataSize: UInt32(entry.data.count),
                crc: crc,
                offset: offset
            ))
            centralDirectory.append(pathData)

            offset += UInt32(localHeader.count + pathData.count + entry.data.count)
        }

        let centralOffset = UInt32(archive.count)
        archive.append(centralDirectory)
        archive.append(endOfCentralDirectory(
            entryCount: UInt16(entries.count),
            centralSize: UInt32(centralDirectory.count),
            centralOffset: centralOffset
        ))

        try archive.write(to: destinationZip, options: .atomic)
    }

    static func extractArchive(from zipURL: URL, to destinationDirectory: URL) throws {
        let data = try Data(contentsOf: zipURL)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        var offset = 0
        while offset + 4 <= data.count {
            let signature = data.readUInt32(at: offset)
            if signature == 0x06054B50 || signature == 0x02014B50 { break }
            guard signature == 0x04034B50 else { throw ZipError.invalidArchive }

            let compressedSize = Int(data.readUInt32(at: offset + 18))
            let fileNameLength = Int(data.readUInt16(at: offset + 26))
            let extraLength = Int(data.readUInt16(at: offset + 28))
            let nameStart = offset + 30
            let nameEnd = nameStart + fileNameLength
            guard nameEnd <= data.count else { throw ZipError.invalidArchive }

            let name = String(data: data.subdata(in: nameStart..<nameEnd), encoding: .utf8) ?? ""
            let dataStart = nameEnd + extraLength
            let dataEnd = dataStart + compressedSize
            guard dataEnd <= data.count else { throw ZipError.invalidArchive }

            let fileData = data.subdata(in: dataStart..<dataEnd)
            let destination = destinationDirectory.appendingPathComponent(name)
            try fileManager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try fileData.write(to: destination, options: .atomic)
            offset = dataEnd
        }
    }

    private static func localFileHeader(
        pathLength: UInt16,
        dataSize: UInt32,
        crc: UInt32,
        offset: UInt32
    ) -> Data {
        var data = Data()
        data.appendUInt32(0x04034B50)
        data.appendUInt16(20) // version
        data.appendUInt16(0) // flags
        data.appendUInt16(0) // store
        data.appendUInt16(0) // mod time
        data.appendUInt16(0) // mod date
        data.appendUInt32(crc)
        data.appendUInt32(dataSize)
        data.appendUInt32(dataSize)
        data.appendUInt16(pathLength)
        data.appendUInt16(0) // extra length
        _ = offset
        return data
    }

    private static func centralFileHeader(
        pathLength: UInt16,
        dataSize: UInt32,
        crc: UInt32,
        offset: UInt32
    ) -> Data {
        var data = Data()
        data.appendUInt32(0x02014B50)
        data.appendUInt16(20) // version made by
        data.appendUInt16(20) // version needed
        data.appendUInt16(0)
        data.appendUInt16(0)
        data.appendUInt16(0)
        data.appendUInt16(0)
        data.appendUInt32(crc)
        data.appendUInt32(dataSize)
        data.appendUInt32(dataSize)
        data.appendUInt16(pathLength)
        data.appendUInt16(0)
        data.appendUInt16(0)
        data.appendUInt16(0)
        data.appendUInt16(0)
        data.appendUInt32(0)
        data.appendUInt32(offset)
        return data
    }

    private static func endOfCentralDirectory(
        entryCount: UInt16,
        centralSize: UInt32,
        centralOffset: UInt32
    ) -> Data {
        var data = Data()
        data.appendUInt32(0x06054B50)
        data.appendUInt16(0)
        data.appendUInt16(0)
        data.appendUInt16(entryCount)
        data.appendUInt16(entryCount)
        data.appendUInt32(centralSize)
        data.appendUInt32(centralOffset)
        data.appendUInt16(0)
        return data
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            var value = (crc ^ UInt32(byte)) & 0xFF
            for _ in 0..<8 {
                value = (value & 1) != 0 ? (value >> 1) ^ 0xEDB8_8320 : value >> 1
            }
            crc = (crc >> 8) ^ value
        }
        return crc ^ 0xFFFF_FFFF
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { append(contentsOf: $0) }
    }

    mutating func appendUInt32(_ value: UInt32) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { append(contentsOf: $0) }
    }

    func readUInt16(at offset: Int) -> UInt16 {
        subdata(in: offset..<(offset + 2)).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
    }

    func readUInt32(at offset: Int) -> UInt32 {
        subdata(in: offset..<(offset + 4)).withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
    }
}
