import SwiftUI

@main
struct MarathonMeetWatchApp: App {
    @StateObject private var watchState = WatchSessionState()

    var body: some Scene {
        WindowGroup {
            RunnerWatchView()
                .environmentObject(watchState)
        }
    }
}
