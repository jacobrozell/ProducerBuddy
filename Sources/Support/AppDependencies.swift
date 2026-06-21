import SwiftUI
import SwiftData

/// Lightweight dependency container for persistence repositories.
@MainActor
struct AppDependencies {
    let songRepository: any SongRepository
    let projectRepository: any ProjectRepository

    static func live(context: ModelContext) -> AppDependencies {
        AppDependencies(
            songRepository: SwiftDataSongRepository(context: context),
            projectRepository: SwiftDataProjectRepository(context: context)
        )
    }
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencies? = nil
}

extension EnvironmentValues {
    var appDependencies: AppDependencies? {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
