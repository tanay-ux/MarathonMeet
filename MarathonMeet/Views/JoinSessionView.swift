import SwiftUI

struct JoinSessionView: View {
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var notificationService: NotificationService

    let role: ParticipantRole

    @State private var displayName = ""
    @State private var sessionCode = ""
    @State private var errorMessage: String?
    @State private var isJoining = false

    private var accent: Color { role == .spectator ? Neo.electricBright : Neo.coral }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                NeoTextField(label: "Your Name", text: $displayName, placeholder: "Tanay")
                    .neoStaggeredAppear(index: 0)

                NeoTextField(
                    label: "Session Code",
                    text: $sessionCode,
                    placeholder: "SF26AB",
                    autocapitalize: .characters
                )
                .neoStaggeredAppear(index: 1)

                Text("Ask the runner for their 6-character session code.")
                    .font(.caption.weight(.semibold))
                    .neoSecondaryText()
                    .neoStaggeredAppear(index: 2)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline.weight(.bold))
                        .neoPrimaryText()
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .neoCard(fill: Neo.pinkSoft)
                        .neoPopIn()
                }

                Button {
                    Task { await joinSession() }
                } label: {
                    HStack {
                        if isJoining { ProgressView().tint(Neo.ink) }
                        Text("Join Session")
                    }
                }
                .buttonStyle(NeoButtonStyle(fill: accent))
                .disabled(!canJoin || isJoining)
                .neoStaggeredAppear(index: 3)
            }
            .padding(20)
        }
        .neoScreen()
        .neoNavigation()
        .navigationTitle(role == .spectator ? "Join as Spectator" : "Join as Runner")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canJoin: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        sessionCode.trimmingCharacters(in: .whitespaces).count >= 4
    }

    private func joinSession() async {
        isJoining = true
        errorMessage = nil
        do {
            try await sessionService.joinSession(
                code: sessionCode,
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                role: role
            )
            if let token = notificationService.fcmToken {
                try? await sessionService.updateFCMToken(token)
            }
            NeoHaptics.success()
            startLocationTracking()
        } catch {
            errorMessage = error.localizedDescription
        }
        isJoining = false
    }

    private func startLocationTracking() {
        if role == .runner {
            locationService.requestAlways()
        } else {
            locationService.requestWhenInUse()
        }
        locationService.startTracking(forRunner: role == .runner, uploadInterval: role == .runner ? 15 : 30) { location in
            Task {
                try? await sessionService.updateLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
        if role == .runner, let threshold = sessionService.currentParticipant?.thresholdMeters {
            WatchConnectivityManager.shared.updateRunnerSession(active: true, threshold: threshold)
        }
    }
}
