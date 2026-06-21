import Foundation
import SwiftData

/// Read/write access to projects without tying callers to SwiftData details.
@MainActor
protocol ProjectRepository {
    func fetchAll() throws -> [Project]
    func insert(_ project: Project)
    func delete(_ project: Project)
    func save() throws
}

struct SwiftDataProjectRepository: ProjectRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Project] {
        try context.fetch(FetchDescriptor<Project>())
    }

    func insert(_ project: Project) {
        context.insert(project)
    }

    func delete(_ project: Project) {
        context.delete(project)
    }

    func save() throws {
        try context.save()
    }
}
