import SwiftData
import SwiftUI

struct ImportFinishRequest {
    let results: [ImportedAudio]
    let failures: [String]
    let existingSongs: [Song]
    let onNeedsReview: (ImportPlan, [String]) -> Void
    let onComplete: (ImportPlan, [String]) -> Void
    let onFailuresOnly: ([String]) -> Void
}

enum LibraryImportActions {
    static func finishImport(_ request: ImportFinishRequest) {
        guard !request.results.isEmpty else {
            request.onFailuresOnly(request.failures)
            return
        }
        let plan = ImportPlanner.plan(request.results, existing: request.existingSongs)
        if plan.needsReview {
            request.onNeedsReview(plan, request.failures)
        } else {
            request.onComplete(plan, request.failures)
        }
    }

    @MainActor
    static func applyImport(
        plan: ImportPlan,
        failures: [String],
        modelContext: ModelContext,
        onSuccess: (String) -> Void,
        onPartialFailure: ([String]) -> Void
    ) {
        let outcome = SongImportService.execute(plan, into: modelContext)
        var parts: [String] = []
        if outcome.newSongs > 0 {
            parts.append("\(outcome.newSongs) new song\(outcome.newSongs == 1 ? "" : "s")")
        }
        if outcome.addedVersions > 0 {
            parts.append("\(outcome.addedVersions) new version\(outcome.addedVersions == 1 ? "" : "s")")
        }
        onSuccess("Imported " + parts.joined(separator: ", "))
        if !failures.isEmpty {
            onPartialFailure(failures)
        }
    }

    static func importFailureMessage(_ failures: [String]) -> String {
        if failures.count == 1 {
            return "Could not import \"\(failures[0])\"."
        }
        return "Could not import \(failures.count) files: \(failures.joined(separator: ", "))."
    }
}
