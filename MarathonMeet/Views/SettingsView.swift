import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let participant = sessionService.currentParticipant {
                        settingsGroup(title: "You", fill: Neo.lavenderSoft) {
                            neoRow("Name", value: participant.displayName)
                            neoRow("Role", value: participant.role == .runner ? "Runner" : "Spectator")
                        }
                    }

                    if let session = sessionService.currentSession {
                        settingsGroup(title: "Session", fill: Neo.sun) {
                            neoRow("Code", value: session.code)
                            if let course = session.courseName {
                                neoRow("Course", value: course)
                            }
                        }
                    }

                    settingsGroup(title: "Permissions", fill: Neo.mintSoft) {
                        neoRow("Location", value: authorizationLabel)
                        if sessionService.currentParticipant?.role == .runner {
                            Button("Open Location Settings") { openSettings() }
                                .buttonStyle(NeoButtonStyle(fill: Neo.mintSoft, isCompact: false))
                        }
                    }

                    Button("Leave Session") { leaveSession() }
                        .buttonStyle(NeoButtonStyle(fill: Neo.pinkSoft))
                }
                .padding(20)
            }
            .neoScreen()
            .neoNavigation()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.black))
                        .neoPrimaryText()
                }
            }
        }
    }

    private func settingsGroup<Content: View>(title: String, fill: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            NeoSectionLabel(text: title, fill: fill)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(16)
            .neoCard(fill: Neo.paper)
        }
    }

    private func neoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .neoSecondaryText()
            Spacer()
            Text(value)
                .font(.subheadline.weight(.black))
                .neoPrimaryText()
        }
    }

    private var authorizationLabel: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "While Using"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        default: return "Not Set"
        }
    }

    private func leaveSession() {
        locationService.stopTracking()
        WatchConnectivityManager.shared.updateRunnerSession(active: false, threshold: 0)
        sessionService.endSession()
        dismiss()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
