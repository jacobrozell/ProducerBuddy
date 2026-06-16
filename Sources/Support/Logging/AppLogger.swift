import Foundation

enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case fault = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum LogCategory: String, Sendable {
    case app
    case ui
    case audio
    case importFlow = "import"
    case persistence
    case analytics
}

struct LogRecord: Sendable {
    let level: LogLevel
    let category: LogCategory
    let eventName: String
    let message: String
    let metadata: [String: String]?
    let correlationId: String?
}

protocol AppLogger: Sendable {
    func log(_ record: LogRecord)
}

extension AppLogger {
    func debug(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        log(LogRecord(
            level: .debug, category: category, eventName: eventName,
            message: message, metadata: metadata, correlationId: nil
        ))
    }

    func info(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        log(LogRecord(
            level: .info, category: category, eventName: eventName,
            message: message, metadata: metadata, correlationId: nil
        ))
    }

    func warning(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        log(LogRecord(
            level: .warning, category: category, eventName: eventName,
            message: message, metadata: metadata, correlationId: nil
        ))
    }

    func error(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        log(LogRecord(
            level: .error, category: category, eventName: eventName,
            message: message, metadata: metadata, correlationId: nil
        ))
    }
}
