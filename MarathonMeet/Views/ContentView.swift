import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionService: SessionService

    var body: some View {
        Group {
            if let participant = sessionService.currentParticipant {
                switch participant.role {
                case .runner:
                    RunnerDashboardView()
                        .neoScreenTransition()
                case .spectator:
                    SpectatorMapView()
                        .neoScreenTransition()
                }
            } else {
                RolePickerView()
                    .neoScreenTransition()
            }
        }
        .animation(NeoMotion.screen, value: sessionService.currentParticipant?.uid)
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionService())
        .environmentObject(LocationService())
        .environmentObject(NotificationService.shared)
}
