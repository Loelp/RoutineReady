import SwiftUI

@main
struct RoutineReadyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootTabView(dependencies: dependencies)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                dependencies.appBecameActive()
            }
        }
    }
}
