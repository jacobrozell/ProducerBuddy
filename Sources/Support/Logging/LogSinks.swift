import Foundation
import os

protocol LogSink: Sendable {
    func write(_ record: LogRecord)
}

struct CompositeLogSink: LogSink {
    let sinks: [LogSink]

    func write(_ record: LogRecord) {
        for sink in sinks {
            sink.write(record)
        }
    }
}

struct ConsoleLogSink: LogSink {
    private let logger = Logger(subsystem: "com.jacobrozell.mixstack", category: "app")

    func write(_ record: LogRecord) {
        let suffix = record.metadata.map { " \($0)" } ?? ""
        let line = "[\(record.category.rawValue)] \(record.eventName): \(record.message)\(suffix)"
        switch record.level {
        case .debug: logger.debug("\(line, privacy: .public)")
        case .info: logger.info("\(line, privacy: .public)")
        case .warning: logger.warning("\(line, privacy: .public)")
        case .error: logger.error("\(line, privacy: .public)")
        case .fault: logger.fault("\(line, privacy: .public)")
        }
    }
}

/// Allowlisted, privacy-safe analytics events. Remote sink is a no-op until Firebase is wired.
struct AnalyticsLogSink: LogSink {
    func write(_ record: LogRecord) {
        guard FeatureFlags.analyticsEnabled else { return }
        guard record.level >= .info else { return }
        guard AnalyticsEventAllowlist.allowed(record.eventName) else { return }
        // Future: FirebaseAnalyticsLogSink adapter (see specs/PlatformParity.md).
        _ = (record.eventName, record.message, record.metadata)
    }
}

enum AnalyticsEventAllowlist {
    static func allowed(_ eventName: String) -> Bool {
        allowedEvents.contains(eventName)
    }

    private static let allowedEvents: Set<String> = [
        "app_launched",
        "main_tab_presented",
        "song_imported",
        "project_created",
        "share_card_exported"
    ]
}

struct DefaultAppLogger: AppLogger {
    private let sink: LogSink

    init(sink: LogSink) {
        self.sink = sink
    }

    static func makeForCurrentBuild() -> DefaultAppLogger {
        DefaultAppLogger(
            sink: CompositeLogSink(sinks: [ConsoleLogSink(), AnalyticsLogSink()])
        )
    }

    func log(_ record: LogRecord) {
        var merged = record.metadata ?? [:]
        if let correlationId = record.correlationId {
            merged["correlation_id"] = correlationId
        }
        let payload = LogRecord(
            level: record.level,
            category: record.category,
            eventName: record.eventName,
            message: record.message,
            metadata: merged.isEmpty ? nil : merged,
            correlationId: record.correlationId
        )
        sink.write(payload)
    }
}

enum AppLog {
    static let shared: AppLogger = DefaultAppLogger.makeForCurrentBuild()
}
